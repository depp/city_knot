library fractal;

import 'package:chronosgl/chronosgl.dart';

const String uIter = "uIter";

void RegisterShaderVars() {
  IntroduceNewShaderVar(uIter, ShaderVarDesc(VarTypeInt, ""));
}

final ShaderObject VertexShader = ShaderObject("Textured")
  ..AddAttributeVars([aPosition, aTexUV])
  ..AddVaryingVars([vTexUV])
  ..SetBodyWithMain([
    "gl_Position = vec4(${aPosition}.xy, 0, 1.0);",
    "${vTexUV} = ${aTexUV};",
  ]);

// http://nuclear.mutantstargoat.com/articles/sdr_fract/

final ShaderObject FragmentShader = ShaderObject("GOL-Fragment")
  ..AddVaryingVars([vTexUV])
  ..SetBody([
    """
    
float getr(float n) {
    if (n < 0.125) return n / 0.125 * 0.8;
    else if (n < 0.25) return (n - 0.125) / 0.125 * 0.2 + 0.8;
    else if (n < 0.75) return 1.0;
    else return 1.0 - (n - 0.75) / 0.25;
}

float getg(float n) {
    if (n < 0.125) return 0.0;
    else if (n < 0.25) return (n - 0.125) / 0.125 * 0.8;
    else if (n < 0.375) return (n - 0.25) / 0.125 * 0.2 + 0.8;
    else if (n < 0.5625) return 1.0;
    else if (n < 0.75) return 1.0 - (n - 0.5625) / 0.1875;
    else return 0.0;
}

 float getb(float n) {
    if (n <= 0.25) return 0.0;
    else if (n < 0.375) return (n - 0.25) / 0.125;
    else if (n < 0.5625) return 1.0 - (n - 0.375) / 0.1875;
    else return 0.0;
}
     
     
float twopi = 2.0 * 3.14159265358979323846264338327950288419716939937510;
  
// https://www.thasler.com/blog/blog/glsl-part2-emu
// Emulation based on Fortran-90 double-single package. See http://crd.lbl.gov/~dhbailey/mpdist/
// https://www.davidhbailey.com/dhbsoftware/
// Substract: res = ds_add(a, b) => res = a + b

// float  => double
vec2 ds(float a) {
    vec2 z;
    z.x = a;
    z.y = 0.0;
    return z;
}

vec2 ds_mult (vec2 dsa, vec2 dsb) {
 vec2 dsc;
 float c11, c21, c2, e, t1, t2;
 float a1, a2, b1, b2, cona, conb, split = 8193.;
 
  cona = dsa.x * split;
  conb = dsb.x * split;
  a1 = cona - (cona - dsa.x);
  b1 = conb - (conb - dsb.x);
  a2 = dsa.x - a1;
  b2 = dsb.x - b1;
 
  c11 = dsa.x * dsb.x;
  c21 = a2 * b2 + (a2 * b1 + (a1 * b2 + (a1 * b1 - c11)));
 
  c2 = dsa.x * dsb.y + dsa.y * dsb.x;
 
  t1 = c11 + c2;
  e = t1 - c11;
  t2 = dsa.y * dsb.y + ((c2 - e) + (c11 - (t1 - e))) + c21;
  
  dsc.x = t1 + t2;
  dsc.y = t2 - (dsc.x - t1);
  
  return dsc;
}

vec2 ds_add (vec2 dsa, vec2 dsb) {
 vec2 dsc;
 float t1, t2, e;
 
  t1 = dsa.x + dsb.x;
  e = t1 - dsa.x;
  t2 = ((dsb.x - e) + (dsa.x - (t1 - e))) + dsa.y + dsb.y;
 
  dsc.x = t1 + t2;
  dsc.y = t2 - (dsc.x - t1);
  return dsc;
}

vec2 ds_sub (vec2 dsa, vec2 dsb) {
 vec2 dsc;
 float e, t1, t2;
 
  t1 = dsa.x - dsb.x;
  e = t1 - dsa.x;
  t2 = ((-dsb.x - e) + (dsa.x - (t1 - e))) + dsa.y - dsb.y;
 
  dsc.x = t1 + t2;
  dsc.y = t2 - (dsc.x - t1);
  return dsc;
}

float ds_compare(vec2 dsa, vec2 dsb) {
  if (dsa.x < dsb.x) return -1.;
  else if (dsa.x == dsb.x) 
         {
         if (dsa.y < dsb.y) return -1.;
         else if (dsa.y == dsb.y) return 0.;
         else return 1.;
         }
  else return 1.;
}


int ${uIter} = 1024;
float threshold = 4.0;

vec2 center = vec2(0.0, 0.0); 

// https://www.youtube.com/watch?time_continue=8&v=zXTpASSd9xE    
vec2 center1 = vec2(-1.749998410993740817490024831624283,
                    -0.00000000000000165712469295418692325);

// https://www.youtube.com/watch?v=pCpLWbHVNhk
vec2 center2 = vec2(0.3602404434376143632361252444495453084826078079585857,
                    -0.641313061064803174860375015179302066579494952282305);
                
vec2 center3 = vec2(0.3750001200618655, -0.2166393884377127);
                





int Compute(vec2 center, float radius, float real, float imag) {
  vec2 r = ds(radius);
  vec2 x = ds_mult(ds(real), r);
  vec2 y = ds_mult(ds(imag), r); 
  vec2 cx = ds_add(ds(center.x), x);
  vec2 cy = ds_add(ds(center.y), y);
  
  x = cx;
  y = cy;
  for(int i=0; i < ${uIter}; i++) {
      vec2 xx = ds_mult(x, x);
      vec2 yy = ds_mult(y, y);
      vec2 abs2 = ds_add(xx, yy);
      if (abs2.x >  threshold) return i;
      
      y = ds_mult(x, y);
      y = ds_mult(ds(2.0), y);
    
      x = ds_sub(xx, yy);
      
      x = ds_add(x, cx);
      y = ds_add(y, cy);
  }
  return 0;
}
      
int ComputeFast(vec2 center, float radius, float real, float imag) {
    vec2 c = center + radius * vec2(real, imag);
    float x = c.x;
    float y = c.y;

    for(int i=0; i < ${uIter}; i++) {
        float xx = x * x;
        float yy = y * y;
        if (xx + yy > threshold) return i;
        
        y = (2.0 * x * y) + c.y;
        x = (xx - yy) + c.x;
    }
    return 0;
}

void main() {
    // vec2 c = 3.0 * (${vTexUV} - 0.5);
    // float r = pow(0.9999, 100000.0 * ${vTexUV}.x) * 2.0;
    float r = pow(0.9999, 200000.0 * (1.0 - ${vTexUV}.x)) * 8.0;
    //float r = (1.0 - ${vTexUV}.x) * 0.01;
    float real = sin(twopi * ${vTexUV}.y);
    float imag = cos(twopi * ${vTexUV}.y);

    int i = Compute(center2, r, real, imag);
    
    float n = float(i) / float(${uIter});
    ${oFragColor}.r  = getr(n);
    ${oFragColor}.g  = getg(n);
    ${oFragColor}.b  = getb(n);
    ${oFragColor}.a  = 1.0;
}   

			
"""
  ]);
