classdef suite2p
    methods(Static)
        function refImg = compute_reference(frames, ops)
            % Computes the reference image by iteratively aligning frames to create reference
            %
            % Parameters
            % ----------
            % ops : struct
            %     Registration options
            % frames : 3D array, int16
            %     size [Ly x Lx x nimg_init], frames to use to create initial reference
            %
            % Returns
            % -------
            % refImg : 2D array, int16
            %     size [Ly x Lx], initial reference image

            % Pick initial reference
            % 将frames转换为GPU数组
            frames = gpuArray(frames);

            % Pick initial reference
            refImg = register.suite2p.pick_initial_reference(frames);
            niter = 8;
            for iter = 1:niter
                % Rigid registration
                [maskMul, maskOffset] = register.suite2p.compute_masks(refImg, 3 * ops.smooth_sigma);
                framesTaper = register.suite2p.apply_masks(frames, maskMul, maskOffset);
                refImgSmooth = register.suite2p.phasecorr_reference(refImg, ops.smooth_sigma);
                [ymax, xmax, cmax] = register.suite2p.phasecorr(framesTaper, refImgSmooth, ops.maxregshift, ops.smooth_sigma_time);

                % Shift frames
                for i = 1:size(frames, 3)
                    frames(:, :, i) = register.suite2p.shift_frame(frames(:, :, i), ymax(i), xmax(i));
                end

                nmax = max(2, floor(size(frames, 3) * (1 + iter) / (2 * niter)));
                [~, isort] = sort(cmax, 'descend');
                isort = isort(1:nmax);

                % Reset reference image
                refImg = int16(mean(frames(:, :, isort), 3));

                % Shift reference image
                refImg = register.suite2p.shift_frame(refImg, -round(mean(ymax(isort))), -round(mean(xmax(isort))));
            end

            % 将refImg转换回CPU数组
            refImg = gather(refImg);
        end

        function [reg_frames, ymax, xmax, cmax] = register_frames(refAndMasks, frames,  ops)

            rmin= -inf;
            rmax=inf;
            % 将frames转换为GPU数组
            frames = gpuArray(frames);
            reg_frames = zeros(size(frames), 'like', frames);

            if length(refAndMasks) == 3 || iscell(refAndMasks)
                maskMul = refAndMasks{1};
                maskOffset = refAndMasks{2};
                cfRefImg = refAndMasks{3};
            else
                error('refAndMasks is not a cell!');
            end

            % Copy frames if smoothing
            fsmooth = single(frames);

            % Apply temporal smoothing if needed
            if ops.smooth_sigma_time > 0
                fsmooth = register.suite2p.temporal_smooth(fsmooth, ops.smooth_sigma_time);
            end

            % Rigid registration
            [ymax, xmax, cmax] = register.suite2p.phasecorr(register.suite2p.apply_masks(min(max(fsmooth, rmin), rmax), maskMul, maskOffset), cfRefImg, ops.maxregshift, ops.smooth_sigma_time);

            % Shift frames
            for i = 1:size(frames, 3)
                reg_frames(:, :, i) = register.suite2p.shift_frame(frames(:, :, i), ymax(i), xmax(i));
            end

            % 将reg_frames转换回CPU数组
            reg_frames = gather(reg_frames);
        end
    end
    methods(Static)
        function refAndMasksAll = compute_reference_masks(refImg, ops)

            % Compute masks
            [maskMul, maskOffset] = register.suite2p.compute_masks(...
                refImg, ...
                3 * ops.smooth_sigma ...
                );

            % Compute phase correlation reference image
            cfRefImg = register.suite2p.phasecorr_reference(...
                refImg, ...
                ops.smooth_sigma ...
                );


            % Return results
            refAndMasksAll = {maskMul, maskOffset, cfRefImg};

        end

        function ops = default_ops()
            ops.smooth_sigma = 1.125;
            ops.maxregshift = 0.1;
            ops.smooth_sigma_time = 0;
        end

        function [ymax, xmax, cmax] = phasecorr(data, cfRefImg, maxregshift, smoothSigmaTime)
            % Compute phase correlation between data and reference image

            % Parameters
            % ----------
            % data : int16
            %     array that's frames x Ly x Lx
            % maxregshift : float
            %     maximum shift as a fraction of the minimum dimension of data (min(Ly,Lx) * maxregshift)
            % smoothSigmaTime : float
            %     how many frames to smooth in time

            % Returns
            % -------
            % ymax : int
            %     shifts in y from cfRefImg to data for each frame
            % xmax : int
            %     shifts in x from cfRefImg to data for each frame
            % cmax : float
            %     maximum of phase correlation for each frame

            minDim = min(size(data, 1), size(data, 2));  % maximum registration shift allowed
            lcorr = min(round(maxregshift * minDim), floor(minDim / 2));

            % Convolve data with cfRefImg
            data = register.suite2p.convolve(data, cfRefImg);
            cc = real([
                data( end-lcorr+1:end, end-lcorr+1:end,:), data(end-lcorr+1:end, 1:lcorr+1,:);
                data(1:lcorr+1, end-lcorr+1:end,:), data( 1:lcorr+1, 1:lcorr+1,:)
                ]);

            if smoothSigmaTime > 0
                cc = register.suite2p.temporal_smooth(cc, smoothSigmaTime);
            end

            nFrames = size(data, 3);
            ymax = zeros(nFrames, 1, 'int32');
            xmax = zeros(nFrames, 1, 'int32');
            cmax = zeros(nFrames, 1,'single');
            for t = 1:nFrames
                [max_val, max_idx] = max(cc(:, :, t), [], 'all', 'linear');
                [ymax(t), xmax(t)] = ind2sub([2*lcorr+1, 2*lcorr+1], max_idx);
                cmax(t) = max_val;
            end

            cmax = cc(sub2ind(size(cc),  ymax, xmax,(1:nFrames)'));
            ymax = ymax - lcorr;
            xmax = xmax - lcorr;
        end
        function frame_shifted = shift_frame(frame, dy, dx)
            %SHIFT_FRAME Shifts the input frame by dy and dx.
            %   frame_shifted = SHIFT_FRAME(frame, dy, dx) returns the frame shifted by
            %   dy (vertical shift) and dx (horizontal shift).
            %
            %   Parameters
            %   ----------
            %   frame: Ly x Lx
            %       The input frame to be shifted.
            %   dy: int
            %       The vertical shift amount.
            %   dx: int
            %       The horizontal shift amount.
            %
            %   Returns
            %   -------
            %   frame_shifted: Ly x Lx
            %       The shifted frame.

            % Shift the frame using circshift function in MATLAB
            frame_shifted = circshift(frame, [-dy, -dx]);
        end

        function convolvedData = convolve(mov, img)
            % Returns the 3D array "mov" convolved by a 2D array "img".

            % Parameters
            % ----------
            % mov: nImg x Ly x Lx
            %     The frames to process
            % img: 2D array
            %     The convolution kernel

            % Returns
            % -------
            % convolvedData: nImg x Ly x Lx

            convolvedData = ifft2(register.suite2p.apply_dotnorm(fft2(mov), img));
        end

        function Y = apply_dotnorm(Y, cfRefImg)
            Y = Y ./ (1e-5 + abs(Y)) .* cfRefImg;
        end



        function maskedData = apply_masks(data, maskMul, maskOffset)
            % Returns a 3D image "data", multiplied by "maskMul" and then added "maskOffset".
            %
            % Parameters
            % ----------
            % data : nImg x Ly x Lx
            % maskMul
            % maskOffset
            %
            % Returns
            % -------
            % maskedData : nImg x Ly x Lx

            % Convert x to single precision (equivalent to np.float32 in Python)
            x_single = double(data);

            % Perform the multiplication and addition
            maskedData = x_single .* maskMul + maskOffset;

            % Convert the result to complex type (equivalent to np.complex64 in Python)
            maskedData = complex(maskedData);
        end

        function [maskMul, maskOffset] = compute_masks(refImg, maskSlope)
            % Returns maskMul and maskOffset from an image and slope parameter
            %
            % Parameters
            % ----------
            % refImg : Ly x Lx
            %     The image
            % maskSlope
            %
            % Returns
            % -------
            % maskMul : float array
            % maskOffset : float array

            [Ly, Lx] = size(refImg);
            maskMul = register.suite2p.spatial_taper(maskSlope, Ly, Lx);
            maskOffset = mean(refImg(:)) .* (1 - maskMul);
        end

        function maskMul = spatial_taper(sig, Ly, Lx)
            % Returns spatial taper on edges with gaussian of std sig
            %
            % Parameters
            % ----------
            % sig
            % Ly: int
            %     frame height
            % Lx: int
            %     frame width
            %
            % Returns
            % -------
            % maskMul

            [xx, yy] = register.suite2p.meshgrid_mean_centered(Lx, Ly);

            mY = ((Ly - 1) / 2) - 2 * sig;
            mX = ((Lx - 1) / 2) - 2 * sig;

            maskY = 1 ./ (1 + exp((yy - mY) / sig));
            maskX = 1 ./ (1 + exp((xx - mX) / sig));

            maskMul = maskY .* maskX;
        end

        function [xx, yy] = meshgrid_mean_centered(x, y)
            % Returns a mean-centered meshgrid
            %
            % Parameters
            % ----------
            % x: int
            %     The height of the meshgrid
            % y: int
            %     The width of the meshgrid
            %
            % Returns
            % -------
            % xx: int array
            % yy: int array

            x = 0:x-1;
            y = 0:y-1;

            x = abs(x - mean(x));
            y = abs(y - mean(y));

            [xx, yy] = meshgrid(x, y);
        end


        function cfRefImg = phasecorr_reference(refImg, smooth_sigma)
            % Returns reference image fft'ed and complex conjugate and multiplied by gaussian filter in the fft domain,
            % with standard deviation "smooth_sigma" computes fft'ed reference image for phasecorr.
            %
            % Parameters
            % ----------
            % refImg : 2D array, int16
            %     reference image
            %
            % Returns
            % -------
            % cfRefImg : 2D array, complex64

            cfRefImg = register.suite2p.complex_fft2(refImg);
            cfRefImg = cfRefImg ./ (1e-5 + abs(cfRefImg));
            cfRefImg = cfRefImg .* register.suite2p.gaussian_fft(smooth_sigma, size(cfRefImg, 1), size(cfRefImg, 2));
        end

        function result = complex_fft2(img, padFft)
            % Returns the complex conjugate of the fft-transformed 2D array "img",
            % optionally padded for speed.
            %
            % Parameters
            % ----------
            % img: Ly x Lx
            %     The image to process
            % padFft: bool
            %     Whether to pad the image

            if nargin < 2
                padFft = false;
            end

            [Ly, Lx] = size(img);

            if padFft
                Ly = 2 ^ nextpow2(Ly);
                Lx = 2 ^ nextpow2(Lx);
                result = conj(fft2(img, Ly, Lx));
            else
                result = conj(fft2(img));
            end
        end


        function fhg = gaussian_fft(sig, Ly, Lx)
            % gaussian filter in the fft domain with std sig and size Ly, Lx
            %
            % Parameters
            % ----------
            % sig
            % Ly : int
            %     frame height
            % Lx : int
            %     frame width
            %
            % Returns
            % -------
            % fhg : array
            %     smoothing filter in Fourier domain

            [xx, yy] = register.suite2p.meshgrid_mean_centered(Lx, Ly);
            hgx = exp(-((xx / sig) .^ 2) / 2);
            hgy = exp(-((yy / sig) .^ 2) / 2);
            hgg = hgy .* hgx;
            hgg = hgg / sum(hgg(:));
            fhg = real(fft2(ifftshift(hgg)));
        end



        function refImg = pick_initial_reference(frames)
            % Computes the initial reference image from a set of frames
            % The input frames should be in the format Ly x Lx x nFrames

            % Get the dimensions of the input frames
            [Ly, Lx, nFrames] = size(frames);

            % Reshape and zero-center the frames
            reshapedFrames = single(reshape(frames, [], nFrames)');
            reshapedFrames = reshapedFrames - mean(reshapedFrames, 2);

            % Compute the normalized cross-correlation matrix
            ccMatrix = reshapedFrames * reshapedFrames';
            normCCMatrix = ccMatrix ./ (sqrt(diag(ccMatrix)) * sqrt(diag(ccMatrix))');

            % Find the frame with the highest average correlation
            numMatches = 19;
            CCsort = sort(normCCMatrix, 2, 'descend');
            bestCC = mean(CCsort(:, 2:(numMatches+1)), 2);
            [~, bestFrameIdx] = max(bestCC);

            % Select the top correlated frames
            [~, indsort] = sort(normCCMatrix(bestFrameIdx, :), 'descend');
            selectedFrameIndices = indsort(1:(numMatches+1));

            % Compute the reference image as the mean of the selected frames
            refImg = mean(reshapedFrames(selectedFrameIndices, :), 1);
            refImg = reshape(refImg, Ly, Lx);
        end
    end
end
