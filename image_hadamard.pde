/*
controls are:
l - load image
L - load brush image
! - downsample image (nearest)
@ - upsample image (nearest)
t - hadamard transform
i - swap real/imag image buffers
o - offset by 1/2
p - shuffle offset
P - inverse of p
q - (press, then move mouse, then release) cut to region
z - (like q) zero region
Z - zero buffer
c - discrete cosine transform
x - inverse of c
f - fake fourier
F - fourier transform
d - zero left of mouse
g - another fake fourier
s - save image
v - blit brush image at mouse with random phase
B - blit brush image at mouse and match phase
b - blit brush image at mouse
m - cycle display mode (real, mag, mag^2)
-/+ - change display gain
1/2 - halve/double buffer
*/
PImage brush;
double[][][] buf;
double[][][] bufi;

//todo implement the fourier hologram involving the planar reference wave from here:
// https://arxiv.org/ftp/arxiv/papers/1306/1306.5066.pdf


void setup(){
  size(512,512);
  pixelDensity(2);
  surface.setResizable(true);
  
  buf = new double[3][pixelWidth][pixelHeight];
  bufi = new double[3][pixelWidth][pixelHeight];
  background(0);
  brush = createImage(8,8,ARGB);//loadImage("ꙮʬꙮ.png");
  brush.loadPixels();
  int i = 0;
  for (int y = 0; y < brush.height; y++){
    int yc = y*2-brush.height;
    for (int x = 0; x < brush.width; x++){
      int xc = x*2-brush.width;
      brush.pixels[i] = color(255,255,255,((yc*yc+xc*xc)<(brush.height*brush.height))?255:0);
      i++;
    }
  }
}

int redraw_timer = 0;
void draw(){
  if (redraw_timer == 1){
    showBuf(scale);
  }
  if (redraw_timer > 0){
    redraw_timer--;
  }
}
int zx,zy;
boolean zp=false;
float scale = 1.;
int mapi(int i){
  return ((i&1) == 0?i/2:-1-i/2)+pixelHeight/2;
}
void onResize(){
  
}
void keyPressed(){
  if (key == '-'){
    scale *= .5;
    showBuf(scale);
  }
  if (key == '='){
    scale *= 2;
    showBuf(scale);
  }
  if (key == '0'){
    scale = 1;
    showBuf(scale);
  }
  if (key == 'l'){
    selectInput("Image to open","openImg");
  }
  if (key == 'L'){
    selectInput("Brush image to open","openBrush");
  }
  if (key == 'd'){
    for(int x = 0; x < mouseX*pixelWidth/width; x++){
      for(int y = 0; y < pixelHeight; y++){
        try_set_buf(x,y,0,0,0);
      }
    }
    showBuf(scale);
  }
  if (key == 'b' || key == 'B' || key == 'v'){
    brush.loadPixels();
    int i = 0;
    int ox = (int)(mouseTX()-brush.width/2);
    int oy = (int)(mouseTY()-brush.height/2);
    for (int y = 0; y < brush.height; y++){
      for (int x = 0; x < brush.width; x++){
        if (alpha(brush.pixels[i])>128){
          if (key=='v'){
            try_set_buf(x+ox,y+oy,randomGaussian(),randomGaussian(),randomGaussian());
            double[][][] t=buf;buf=bufi;bufi=t;
            try_set_buf(x+ox,y+oy,randomGaussian(),randomGaussian(),randomGaussian());
            t=buf;buf=bufi;bufi=t;
          }
          try_set_buf(x+ox,y+oy,
          red(brush.pixels[i]),
          green(brush.pixels[i]),
          blue(brush.pixels[i]),key!='b');
        }
        i++;
      }
    }
    showBuf(scale);
  }
  if (key == 's'){
    rendBuf(scale).save("out.png");
    //save("out.png");
  }
  if (key == 't'){
    for (double[][] b:buf){
      hadamard2d(b);
    }
    scaleBuf(buf,1./Math.sqrt(buf[0].length*buf[0][0].length));
    showBuf(scale);
  }
  if (key == 'f'){
    for (double[][] b:buf){
      fftr2d(b);
    }
    scaleBuf(buf,2./pixelWidth);
    showBuf(scale);
  }
  if (key == 'F'){
    for (int i = 0; i < 3; i++){
      Complex[][] c = new Complex[buf[0].length][buf[0][0].length];
      for(int x = 0; x < c.length; x++){
        for(int y = 0; y < c[x].length; y++){
          c[x][y] = new Complex(buf[i][x][y],bufi[i][x][y]);
        }
      }
      c = fft2d(c);
      for(int x = 0; x < c.length; x++){
        for(int y = 0; y < c[x].length; y++){
          buf[i][x][y] = c[x][y].re;
          bufi[i][x][y] = c[x][y].im;
        }
      }
    }
    scaleBuf(buf,1./Math.sqrt(buf[0].length*buf[0][0].length));
    scaleBuf(bufi,1./Math.sqrt(buf[0].length*buf[0][0].length));
    showBuf(scale);
  }
  if (key == 'i'){
    double[][][] t = buf;buf=bufi;bufi=t;
    showBuf(scale);
  }
  if (key == 'g'){
    for (double[][] b:buf){
      fft2d(b);
    }
    scaleBuf(buf,2./pixelWidth);
    showBuf(scale);
  }
  if (key == 'c'){
    for (double[][] b:buf){
      dct2d(b);
    }
    scaleBuf(buf,2./(pixelWidth));
    showBuf(scale);
  }
  if (key == 'x'){
    for (double[][] b:buf){
      idct2d(b);
    }
    scaleBuf(buf,2./(pixelWidth));
    showBuf(scale);
  }
  if (key == 'z' || key == 'q'){
    if (zp){}else{
    zx = (int)mouseTX();zy = (int)mouseTY();
    zp = true;
    }
  }
  if (key == 'Z'){
    scaleBuf(buf,0);
    showBuf(scale);
  }
  if (key == 'o'){
    for (int i = 0; i < 3;i++){
      for (int x = 0; x < pixelWidth; x++){
        for (int y = 0; y < pixelHeight/2; y++){
          double t = buf[i][x][y];
          buf[i][x][y] = buf[i][x][y+pixelHeight/2];
          buf[i][x][y+pixelHeight/2] = t;
        }
      }
      for (int x = 0; x < pixelWidth; x++){
        for (int y = 0; y < pixelHeight/2; y++){
          double t = buf[i][y][x];
          buf[i][y][x] = buf[i][y+pixelHeight/2][x];
          buf[i][y+pixelHeight/2][x] = t;
        }
      }
    }
    showBuf(scale);
  }
  if (key == 'P'){
    double[] tmp = new double[pixelWidth];
    for (int i = 0; i < 3;i++){
      for (int x = 0; x < pixelWidth; x++){
        for (int y = 0; y < pixelHeight; y++){
          tmp[y] = buf[i][x][y];
        }
        for (int y = 0; y < pixelHeight; y++){
          buf[i][x][y] = tmp[mapi(y)];
        }
      }
      for (int x = 0; x < pixelWidth; x++){
        for (int y = 0; y < pixelHeight; y++){
          tmp[y] = buf[i][y][x];
        }
        for (int y = 0; y < pixelHeight; y++){
          buf[i][y][x] = tmp[mapi(y)];
        }
      }
    }
    showBuf(scale);
  }
  if (key == 'p'){
    double[] tmp = new double[pixelWidth];
    for (int i = 0; i < 3;i++){
      for (int x = 0; x < pixelWidth; x++){
        for (int y = 0; y < pixelHeight; y++){
          tmp[mapi(y)] = buf[i][x][y];
        }
        for (int y = 0; y < pixelHeight; y++){
          buf[i][x][y] = tmp[y];
        }
      }
      for (int x = 0; x < pixelWidth; x++){
        for (int y = 0; y < pixelHeight; y++){
          tmp[mapi(y)] = buf[i][y][x];
        }
        for (int y = 0; y < pixelHeight; y++){
          buf[i][y][x] = tmp[y];
        }
      }
    }
    showBuf(scale);
  }
  if (key == 'm'){
    showMode = (showMode+1)%3;
    showBuf(scale);
  }
  
  if(key == '1'){
    scaleBuf(buf,.5);
    scaleBuf(bufi,.5);
    showBuf(scale);
  }
  if(key == '2'){
    scaleBuf(buf,2);
    scaleBuf(bufi,2);
    showBuf(scale);
  }
  if(key == '!'){
    for (int i = 0; i < 3; i++){
      buf[i] = resamp_buf(buf[i],buf[i].length/2,buf[i][0].length/2);
      bufi[i] = resamp_buf(bufi[i],bufi[i].length/2,bufi[i][0].length/2);
    }
    showBuf(scale);
  }
  if(key == '@'){
    for (int i = 0; i < 3; i++){
      buf[i] = resamp_buf(buf[i],buf[i].length*2,buf[i][0].length*2);
      bufi[i] = resamp_buf(bufi[i],bufi[i].length*2,bufi[i][0].length*2);
    }
    showBuf(scale);
  }
}
double[][] resamp_buf(double[][] b, int w, int h){
  double[][] r = new double[w][h];
  for (int y = 0; y < h; y++){
    int by = y*b[0].length/h;
    for (int x = 0; x < w; x++){
      int bx = x*b.length/w;
      r[x][y] = b[bx][by];
    }
  }
  return r;
}
int np2(int i){
  i -= 1;
  i |= i>>1;
  i |= i>>2;
  i |= i>>4;
  i |= i>>8;
  i |= i>>16;
  return i+1;
}
void openImg(File sel){
    PImage img=loadImage(sel.getAbsolutePath());
    //scale up to next pow 2 size
    img.resize(np2(img.width),np2(img.height));
    imbuf(img);
    copy_to_im();
    scaleBuf(bufi,0);
    redraw_timer = 1;
}
void openBrush(File sel){
    brush=loadImage(sel.getAbsolutePath());
}
void keyReleased(){
  int mx = (int)mouseTX();
  int my = (int)mouseTY();
  if (key == 'z'){
    zp = false;

    for (int x = min(zx, mx); x <= max(zx, mx); x++){
      for (int y = min(zy, my); y <= max(zy, my); y++){
        try_set_buf(x,y,0,0,0);
      }
    }
    showBuf(scale);
  }
  if (key == 'q'){
    zp = false;
    for (int x = 0; x < buf[0].length; x++){
      for (int y = 0; y < buf[0][x].length; y++){
        if (x<=min(zx, mx) || x>max(zx, mx) || 
            y<=min(zy, my) || y>max(zy, my)){
          for (int i = 0; i < 3; i++){
            buf[i][x][y] = 0;
          }
        }
      }
    }
    showBuf(scale);
  }
}
double cr=127,cg=127,cb=127;
int ox=0,oy=0;
void mousePressed(){
  ox = mouseX*pixelWidth/width;
  oy = mouseY*pixelHeight/height;
  try_set_buf(ox,oy,cr,cg,cb);
  showBuf(scale);
}

void mouseDragged(){
  int nx = mouseX*pixelWidth/width;
  int ny = mouseY*pixelHeight/height;
  int dx = nx-ox;
  int dy = ny-oy;
  int sx = dx>=0?1:-1;
  int sy = dy>=0?1:-1;
  boolean sw = dx*sx<dy*sy;
  int cx = sw?oy*sy:ox*sx;
  int gx = sw?ny*sy:nx*sx;
  int gy = sw?nx*sx:ny*sy;
  if (cx < gx){
    double cy = sw?ox*sx:oy*sy;
    double iy = (cy-gy)/(cx-gx);
    //print("d");
    for (int x = cx; x <= gx; x ++){
      cy += iy;
      if (sw){
        try_set_buf((int)cy*sy,x*sx,cr,cg,cb);
      }else{
        try_set_buf(x*sx,(int)cy*sy,cr,cg,cb);
      }
    }
  }
  ox = nx;
  oy = ny;
  redraw_timer = 1;
}
void imbuf(PImage img){
  buf = new double[3][img.width][img.height];
  int i = 0;
  img.loadPixels();
  for (int y = 0; y < buf[0][0].length; y++){
    for (int x = 0; x < buf[0].length; x++){
      buf[0][x][y] = red(img.pixels[i]);
      buf[1][x][y] = green(img.pixels[i]);
      buf[2][x][y] = blue(img.pixels[i]);
      i++;
    }
  }
}
float mouseTX(){
  return ((float)mouseX)/width *buf[0].length   ;
}
float mouseTY(){
  return ((float)mouseY)/height*buf[0][0].length;
}
Complex mouseT(){
  return new Complex(mouseTX(),mouseTY());
}
void copy_to_im(){
  bufi = new double[3][buf[0].length][buf[0][0].length];
  for (int y = 0; y < buf[0][0].length; y++){
    for (int x = 0; x < buf[0].length; x++){
      bufi[0][x][y] = buf[0][x][y];
      bufi[1][x][y] = buf[1][x][y];
      bufi[2][x][y] = buf[2][x][y];
    }
  }
}
void try_set_buf(int x, int y, double r, double g, double b){
  try_set_buf(x,y,r,g,b,false);
}
void try_set_buf(int x, int y, double r, double g, double b,boolean keepPhase){
  if (x>=0 && x<buf[0].length){
    if (y>=0 && y<buf[0][x].length){
      if (keepPhase){
        for(int i = 0; i < 3; i ++){
          double c = i==0?r:i==1?g:b;
          double m = Math.hypot(buf[i][x][y],bufi[i][x][y]);
          if (m == 0){
            buf[i][x][y] = c;
          }else{
            buf[i][x][y] *= c/m;
            bufi[i][x][y] *= c/m;
          }
        }
      }else{
        buf[0][x][y] = r;buf[1][x][y] = g;buf[2][x][y] = b;
      }
    }
  }
}

color fcolor(double r, double g, double b){
  return color(min(255,max(0,(float)r)),min(255,max(0,(float)g)),min(255,max(0,(float)b)));
}
double mag2(double a, double b){return a*a+b*b;}
int showMode=0;
PImage rendBuf(float scale){
  PImage bufimg = createImage(buf[0].length,buf[0][0].length,RGB);
  int i = 0;
  bufimg.loadPixels();
  for (int y = 0; y < buf[0][0].length; y++){
    for (int x = 0; x < buf[0].length; x++){
      color c;
      if (showMode == 0)
        c = fcolor(buf[0][x][y]*scale,buf[1][x][y]*scale,buf[2][x][y]*scale);
      else if (showMode == 1)
        c = fcolor(Math.hypot(buf[0][x][y],bufi[0][x][y])*scale,
                   Math.hypot(buf[1][x][y],bufi[1][x][y])*scale,
                   Math.hypot(buf[2][x][y],bufi[2][x][y])*scale);
      else if (showMode == 2)
        c = fcolor(mag2(buf[0][x][y],bufi[0][x][y])*scale,
                   mag2(buf[1][x][y],bufi[1][x][y])*scale,
                   mag2(buf[2][x][y],bufi[2][x][y])*scale);
      else
        c = color(0);
      //set(x,y,c);
      bufimg.pixels[i] = c;
      i++;
    }
  }  
  bufimg.updatePixels();
  return bufimg;
}
void showBuf(float scale){
  image(rendBuf(scale),0,0,width,height);
}


double[][][] scaleBuf(double[][][] b,double s){
  for(int i = 0; i < b.length; i++){
    for(int j = 0; j < b[i].length; j++){
      for(int k = 0; k < b[i][j].length; k++){
        b[i][j][k] *= s;
      }
    }
  }
  return b;
}





double[][] transpose(double[][] arr){
  for (int x = 0; x < arr.length; x++){
    for (int y = x+1; y < arr.length; y++){
      double t = arr[x][y];
      arr[x][y] = arr[y][x];
      arr[y][x] = t;
    }
  }
  return arr;
}
double[][] dct2d(double[][] arr){
  transpose(arr);
  for (int x = 0; x < arr.length; x++){
    FastDctLee.transform(arr[x]);
  }
  transpose(arr);
  for (int x = 0; x < arr.length; x++){
    FastDctLee.transform(arr[x]);
  }
  return arr;
}
double[][] idct2d(double[][] arr){
  for (int x = 0; x < arr.length; x++){
    FastDctLee.inverseTransform(arr[x]);
  }
  transpose(arr);
  for (int x = 0; x < arr.length; x++){
    FastDctLee.inverseTransform(arr[x]);
  }
  transpose(arr);
  return arr;
}

double[][] hadamard2d(double[][] arr){
  for (int x = 0; x < arr.length; x++){
    hadamard1d(arr[x]);
  }
  for (int y = 0; y < arr[0].length; y++){
    hadamard1d(y,arr);
  }
  return arr;
}

double[] hadamard1d(double[] arr){
  return hadamard1d(arr,arr.length);
}
double[] hadamard1d(double[] arr,int stride){
  if (stride <= 1){
    return arr;
  }
  for (int i = 0; i < arr.length; i += stride){
    for (int j = 0; j < stride>>1; j++){
      int i0 = i+j;
      int i1 = i0+(stride>>1);
      double tmp = arr[i0];
      arr[i0] += arr[i1];
      arr[i1] -= tmp;
    }
  }
  return hadamard1d(arr,stride>>1);
}
double[][] hadamard1d(int ind,double[][] arr){
  return hadamard1d(ind,arr,arr.length);
}
double[][] hadamard1d(int ind,double[][] arr,int stride){
  if (stride <= 1){
    return arr;
  }
  for (int i = 0; i < arr.length; i += stride){
    for (int j = 0; j < stride>>1; j++){
      int i0 = i+j;
      int i1 = i0+(stride>>1);
      double tmp = arr[i0][ind];
      arr[i0][ind] += arr[i1][ind];
      arr[i1][ind] -= tmp;
    }
  }
  return hadamard1d(ind,arr,stride>>1);
}

double[][] fftr2d(double[][] arr){
  transpose(arr);
  for (int x = 0; x < arr.length; x++){
    fftr1d(arr[x]);
  }
  transpose(arr);
  for (int x = 0; x < arr.length; x++){
    fftr1d(arr[x]);
  }
  return arr;
}
double[][] fft2d(double[][] arr){
  Complex[][] c = new Complex[arr.length][arr[0].length];
  for(int x = 0; x < c.length; x++){
    for(int y = 0; y < c[x].length; y++){
      c[x][y] = new Complex(arr[x][y],arr[(x+(c.length/2))%c.length][y]);
    }
  }
  c = fft2d(c);
  for(int x = 0; x < c.length; x++){
    for(int y = 0; y < c[x].length; y++){
      arr[x][y] = ((x*2>=c.length)!=(y*2>=c[x].length))?c[x][y].im:c[x][y].re;
    }
  }
  return arr;
}
Complex[][] fft2d(Complex[][] arr){
  for(int x = 0; x < arr.length; x++){
    arr[x] = FFT.fft(arr[x]);
  }
  for(int x = 0; x < arr[0].length; x++){
    Complex[] c = new Complex[arr.length];
    for (int i = 0; i < c.length; i++){
      c[i] = arr[i][x];
    }
    c = FFT.fft(c);
    for (int i = 0; i < c.length;i++ ){
      arr[i][x] = c[i];
    }
  }
  return arr;
}
double[] fftr1d(double[] arr){
  Complex[] c = new Complex[arr.length/2];
  for (int i = 0; i < c.length; i++){
    c[i] = new Complex(arr[i*2],arr[i*2+1]);
  }
  c = FFT.fft(c);
  for (int i = 0; i < c.length;i++){
    arr[i*2] = c[i].re;
    arr[i*2+1] = c[i].im;
  }
  return arr;
  /*double[] tw = new double[arr.length];
  for (int i = 0; i < tw.length; i++){
    tw[i] = Math.cos(i*2*Math.PI/tw.length);
  }
  double[] im = new double[arr.length];
  fft1d(arr,im,tw);
  //for (int i = arr.length/2; i < arr.length;i++){
  //  arr[i] = im[i];
  //}
  return arr;*/
}
void fft1d(double[] re,double[] im,double[] tw){
  for (int stride = 2; stride < re.length; stride<<= 1){
    for (int i = 0; i < re.length; i += stride){
      for (int j = 0; j < stride>>1; j++){
        //z[i+j] 
        double tr = re[i+j];
        double ti = im[i+j];
        int i2 = i+j+(stride>>1);
        int it = j*re.length/stride;
        int iti = (it+re.length/4)%tw.length;
        double ttr = re[i2]*tw[it]-im[i2]*tw[iti];
        double tti = re[i2]*tw[iti]+im[i2]*tw[it];
        re[i2] = re[i+j]-ttr;
        im[i2] = im[i+j]-tti;
        re[i+j] += ttr;
        im[i+j] += tti;
      }
    }
  }
}
