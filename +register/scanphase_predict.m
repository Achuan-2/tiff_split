function bidiphase = scanphase_predict(imgStack)
    % Returns the bidirectional phase offset, the offset between lines that sometimes occurs in line scanning.
    % frames :  Height x Width × frames

    % Transfer imgStack to GPU
    imgStack = gpuArray(imgStack);

    [~, Width, ~] = size(imgStack);

    % compute phase-correlation between lines in x-direction
    d1 = fft(imgStack(2:2:end,:, :), [], 2);
    d1 = d1 ./ (abs(d1) + 1e-5);

    d2 = conj(fft(imgStack(1:2:end,:,:), [], 2));
    d2 = d2 ./ (abs(d2) + 1e-5);

    d2 = d2(1:size(d1,1), :, :);
    cc = real(ifft(d1 .* d2, [], 2));
    cc = mean(mean(cc, 3), 1);
    cc = fftshift(cc);

    % Transfer cc back to CPU for the final computation
    cc = gather(cc);

    % max shift of +/-5 pixels
    [~, ix] = max(cc(floor(Width/2)+1 + (-5:5)));
    bidiphase = -(ix-6);
end
