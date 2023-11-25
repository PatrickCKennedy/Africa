% PK
% Detecting transposable elements with reper

git clone https://github.com/nterhoeven/reper.git
cd reper
docker build --platform linux/amd64 .

alias reper="docker run --user=$(id -u):$(id -g) -it --rm -v $(pwd):/data nterhoeven/reper"
--platform linux/amd64
