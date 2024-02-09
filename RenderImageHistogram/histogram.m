img = imread('RenderImagePoints/Lenna.png');
figure; imshow(img); title('Original Image');

% Separate the color channels
redChannel = img(:,:,1);
greenChannel = img(:,:,2);
blueChannel = img(:,:,3);

% Plot histogram for the Red channel
figure; imhist(redChannel); title('Histogram of Red Channel');
xlim([0 255]); % Limit x-axis from 0 to 255
xlabel('Pixel Intensity'); ylabel('Count');

% Plot histogram for the Green channel
figure; imhist(greenChannel); title('Histogram of Green Channel');
xlim([0 255]); % Limit x-axis from 0 to 255
xlabel('Pixel Intensity'); ylabel('Count');

% Plot histogram for the Blue channel
figure; imhist(blueChannel); title('Histogram of Blue Channel');
xlim([0 255]); % Limit x-axis from 0 to 255
xlabel('Pixel Intensity'); ylabel('Count');

