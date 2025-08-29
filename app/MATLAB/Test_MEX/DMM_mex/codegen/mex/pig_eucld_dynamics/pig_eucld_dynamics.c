/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * pig_eucld_dynamics.c
 *
 * Code generation for function 'pig_eucld_dynamics'
 *
 */

/* Include files */
#include "pig_eucld_dynamics.h"
#include "expm.h"
#include "rt_nonfinite.h"
#include "sumMatrixIncludeNaN.h"
#include "mwmathutil.h"
#include <math.h>
#include <string.h>

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = {
    25,                   /* lineNo */
    "pig_eucld_dynamics", /* fcnName */
    "F:\\Academic\\Dropbox\\Recent\\WorkQC\\Experiment for 100km "
    "data\\FSP_ver0r3_speed\\Test_MEX\\DMM_mex\\pig_eucld_dynamics.m" /* pathName
                                                                       */
};

static emlrtRSInfo b_emlrtRSI = {
    27,                   /* lineNo */
    "pig_eucld_dynamics", /* fcnName */
    "F:\\Academic\\Dropbox\\Recent\\WorkQC\\Experiment for 100km "
    "data\\FSP_ver0r3_speed\\Test_MEX\\DMM_mex\\pig_eucld_dynamics.m" /* pathName
                                                                       */
};

static emlrtRSInfo c_emlrtRSI = {
    51,     /* lineNo */
    "expm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo d_emlrtRSI = {
    56,     /* lineNo */
    "expm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo e_emlrtRSI = {
    60,     /* lineNo */
    "expm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo f_emlrtRSI = {
    61,     /* lineNo */
    "expm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo ob_emlrtRSI =
    {
        32,          /* lineNo */
        "quat2rotm", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\quat2rot"
        "m.m" /* pathName */
};

static emlrtRSInfo pb_emlrtRSI =
    {
        43,          /* lineNo */
        "quat2rotm", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\quat2rot"
        "m.m" /* pathName */
};

static emlrtRSInfo qb_emlrtRSI =
    {
        44,          /* lineNo */
        "quat2rotm", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\quat2rot"
        "m.m" /* pathName */
};

static emlrtRSInfo rb_emlrtRSI =
    {
        45,          /* lineNo */
        "quat2rotm", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\quat2rot"
        "m.m" /* pathName */
};

static emlrtRSInfo sb_emlrtRSI = {
    15,              /* lineNo */
    "normalizeRows", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\+robotics\\+"
    "internal\\normalizeRows.m" /* pathName */
};

static emlrtRTEInfo emlrtRTEI = {
    62,     /* lineNo */
    13,     /* colNo */
    "expm", /* fName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pName
                                                                        */
};

static emlrtRTEInfo b_emlrtRTEI = {
    13,     /* lineNo */
    9,      /* colNo */
    "sqrt", /* fName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\elfun\\sqrt.m" /* pName
                                                                       */
};

/* Function Definitions */
void pig_eucld_dynamics(const emlrtStack *sp, real_T t, const real_T x[17],
                        const real_T u[6], const real_T params[8],
                        real_T x_next[17])
{
  static const real_T theta[5] = {0.01495585217958292, 0.253939833006323,
                                  0.95041789961629319, 2.097847961257068,
                                  5.3719203511481517};
  static const real_T gl[3] = {0.0, 0.0, -9.81};
  static const uint8_T uv[5] = {3U, 5U, 7U, 9U, 13U};
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack st;
  real_T c_x[17];
  real_T a[16];
  real_T y[16];
  real_T C_nb[9];
  real_T tempR[9];
  real_T normRowMatrix[4];
  real_T b_C_nb[3];
  real_T absx;
  real_T b_x;
  real_T b_y_tmp;
  real_T c_y_tmp;
  real_T s;
  real_T scale;
  real_T w_b_idx_0;
  real_T w_b_idx_1;
  real_T y_tmp;
  int32_T eint;
  int32_T i;
  int32_T i1;
  int32_T j;
  int32_T s_tmp;
  int8_T n;
  boolean_T exitg1;
  (void)t;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  /*  equatorial (Wikipedia)  */
  /*  polar (Wikipedia)  */
  /*  manifold is default  */
  /*  earth rotation is default value  */
  /*  radians per second [=7.292115e-5*180/pi*86400 = 360.9856]  */
  /*  o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17) [+]
   * imu_a <--u(1:3) | imu_w <--u(4:6)   */
  /*  prms(8)*v; [NO Scaling] */
  if (muDoubleScalarIsInf(x[1]) || muDoubleScalarIsNaN(x[1])) {
    b_x = rtNaN;
  } else {
    b_x = muDoubleScalarRem(x[1], 360.0);
    absx = muDoubleScalarAbs(b_x);
    if (absx > 180.0) {
      if (b_x > 0.0) {
        b_x -= 360.0;
      } else {
        b_x += 360.0;
      }
      absx = muDoubleScalarAbs(b_x);
    }
    if (absx <= 45.0) {
      b_x *= 0.017453292519943295;
      n = 0;
    } else if (absx <= 135.0) {
      if (b_x > 0.0) {
        b_x = 0.017453292519943295 * (b_x - 90.0);
        n = 1;
      } else {
        b_x = 0.017453292519943295 * (b_x + 90.0);
        n = -1;
      }
    } else if (b_x > 0.0) {
      b_x = 0.017453292519943295 * (b_x - 180.0);
      n = 2;
    } else {
      b_x = 0.017453292519943295 * (b_x + 180.0);
      n = -2;
    }
    if (n == 0) {
      b_x = muDoubleScalarCos(b_x);
    } else if (n == 1) {
      b_x = -muDoubleScalarSin(b_x);
    } else if (n == -1) {
      b_x = muDoubleScalarSin(b_x);
    } else {
      b_x = -muDoubleScalarCos(b_x);
    }
  }
  w_b_idx_0 = params[3] * u[3] + x[14];
  w_b_idx_1 = params[4] * u[4] + x[15];
  absx = params[5] * u[5] + x[16];
  y[0] = 0.0 * params[6];
  y_tmp = 0.5 * -w_b_idx_0 * params[6];
  y[4] = y_tmp;
  b_y_tmp = 0.5 * -w_b_idx_1 * params[6];
  y[8] = b_y_tmp;
  c_y_tmp = 0.5 * -absx * params[6];
  y[12] = c_y_tmp;
  s = 0.5 * w_b_idx_0 * params[6];
  y[1] = s;
  y[5] = 0.0 * params[6];
  absx = 0.5 * absx * params[6];
  y[9] = absx;
  y[13] = b_y_tmp;
  b_y_tmp = 0.5 * w_b_idx_1 * params[6];
  y[2] = b_y_tmp;
  y[6] = c_y_tmp;
  y[10] = 0.0 * params[6];
  y[14] = s;
  y[3] = absx;
  y[7] = b_y_tmp;
  y[11] = y_tmp;
  y[15] = 0.0 * params[6];
  st.site = &emlrtRSI;
  absx = 0.0;
  j = 0;
  exitg1 = false;
  while ((!exitg1) && (j < 4)) {
    s_tmp = j << 2;
    s = ((muDoubleScalarAbs(y[s_tmp]) + muDoubleScalarAbs(y[s_tmp + 1])) +
         muDoubleScalarAbs(y[s_tmp + 2])) +
        muDoubleScalarAbs(y[s_tmp + 3]);
    if (muDoubleScalarIsNaN(s)) {
      absx = rtNaN;
      exitg1 = true;
    } else {
      if (s > absx) {
        absx = s;
      }
      j++;
    }
  }
  if (absx <= 5.3719203511481517) {
    s_tmp = 0;
    exitg1 = false;
    while ((!exitg1) && (s_tmp < 5)) {
      if (absx <= theta[s_tmp]) {
        b_st.site = &c_emlrtRSI;
        PadeApproximantOfDegree(&b_st, y, uv[s_tmp], a);
        exitg1 = true;
      } else {
        s_tmp++;
      }
    }
  } else {
    b_st.site = &d_emlrtRSI;
    absx /= 5.3719203511481517;
    if ((!muDoubleScalarIsInf(absx)) && (!muDoubleScalarIsNaN(absx))) {
      absx = frexp(absx, &eint);
    } else {
      eint = 0;
    }
    s = eint;
    if (absx == 0.5) {
      s = (real_T)eint - 1.0;
    }
    b_st.site = &e_emlrtRSI;
    b_y_tmp = muDoubleScalarPower(2.0, s);
    for (eint = 0; eint < 16; eint++) {
      y[eint] /= b_y_tmp;
    }
    b_st.site = &f_emlrtRSI;
    PadeApproximantOfDegree(&b_st, y, 13U, a);
    eint = (int32_T)s;
    emlrtForLoopVectorCheckR2021a(1.0, 1.0, s, mxDOUBLE_CLASS, (int32_T)s,
                                  &emlrtRTEI, &st);
    for (j = 0; j < eint; j++) {
      for (i = 0; i < 4; i++) {
        for (i1 = 0; i1 < 4; i1++) {
          s_tmp = i1 << 2;
          y[i + s_tmp] = ((a[i] * a[s_tmp] + a[i + 4] * a[s_tmp + 1]) +
                          a[i + 8] * a[s_tmp + 2]) +
                         a[i + 12] * a[s_tmp + 3];
        }
      }
      memcpy(&a[0], &y[0], 16U * sizeof(real_T));
    }
  }
  st.site = &b_emlrtRSI;
  b_st.site = &ob_emlrtRSI;
  normRowMatrix[0] = muDoubleScalarPower(x[4], 2.0);
  normRowMatrix[1] = muDoubleScalarPower(x[5], 2.0);
  normRowMatrix[2] = muDoubleScalarPower(x[6], 2.0);
  normRowMatrix[3] = muDoubleScalarPower(x[7], 2.0);
  absx = sumColumnB(normRowMatrix);
  c_st.site = &sb_emlrtRSI;
  if (absx < 0.0) {
    emlrtErrorWithMessageIdR2018a(
        &c_st, &b_emlrtRTEI, "Coder:toolbox:ElFunDomainError",
        "Coder:toolbox:ElFunDomainError", 3, 4, 4, "sqrt");
  }
  absx = muDoubleScalarSqrt(absx);
  absx = 1.0 / absx;
  normRowMatrix[0] = x[4] * absx;
  normRowMatrix[1] = x[5] * absx;
  normRowMatrix[2] = x[6] * absx;
  normRowMatrix[3] = x[7] * absx;
  b_st.site = &pb_emlrtRSI;
  b_st.site = &pb_emlrtRSI;
  b_st.site = &qb_emlrtRSI;
  b_st.site = &qb_emlrtRSI;
  b_st.site = &rb_emlrtRSI;
  b_st.site = &rb_emlrtRSI;
  absx = normRowMatrix[3] * normRowMatrix[3];
  s = normRowMatrix[2] * normRowMatrix[2];
  tempR[0] = 1.0 - 2.0 * (s + absx);
  scale = normRowMatrix[1] * normRowMatrix[2];
  y_tmp = normRowMatrix[0] * normRowMatrix[3];
  tempR[1] = 2.0 * (scale - y_tmp);
  b_y_tmp = normRowMatrix[1] * normRowMatrix[3];
  c_y_tmp = normRowMatrix[0] * normRowMatrix[2];
  tempR[2] = 2.0 * (b_y_tmp + c_y_tmp);
  tempR[3] = 2.0 * (scale + y_tmp);
  scale = normRowMatrix[1] * normRowMatrix[1];
  tempR[4] = 1.0 - 2.0 * (scale + absx);
  absx = normRowMatrix[2] * normRowMatrix[3];
  y_tmp = normRowMatrix[0] * normRowMatrix[1];
  tempR[5] = 2.0 * (absx - y_tmp);
  tempR[6] = 2.0 * (b_y_tmp - c_y_tmp);
  tempR[7] = 2.0 * (absx + y_tmp);
  tempR[8] = 1.0 - 2.0 * (scale + s);
  memcpy(&C_nb[0], &tempR[0], 9U * sizeof(real_T));
  for (eint = 0; eint < 3; eint++) {
    s_tmp = 3 * eint;
    C_nb[eint] = tempR[s_tmp];
    C_nb[eint + 3] = tempR[s_tmp + 1];
    C_nb[eint + 6] = tempR[s_tmp + 2];
  }
  /*  C_nb =
   * [-0.999487613146384,0.029287284528011,-0.011579364117620;-0.029993627022430,-0.771198451711062,0.635845821441784;0.009692736486792,0.635867574759681,0.771681529525928];
   */
  /*  disp(quat2rotm(q_gen')-C_nb) */
  scale = 3.3121686421112381E-170;
  /*  [not needed] /norm(q_gen(q,bs,imu_w));  */
  absx = muDoubleScalarAbs(x[8]);
  if (absx > 3.3121686421112381E-170) {
    b_y_tmp = 1.0;
    scale = absx;
  } else {
    s = absx / 3.3121686421112381E-170;
    b_y_tmp = s * s;
  }
  w_b_idx_0 = params[0] * u[0] + x[11];
  absx = muDoubleScalarAbs(x[9]);
  if (absx > scale) {
    s = scale / absx;
    b_y_tmp = b_y_tmp * s * s + 1.0;
    scale = absx;
  } else {
    s = absx / scale;
    b_y_tmp += s * s;
  }
  w_b_idx_1 = params[1] * u[1] + x[12];
  absx = muDoubleScalarAbs(x[10]);
  if (absx > scale) {
    s = scale / absx;
    b_y_tmp = b_y_tmp * s * s + 1.0;
    scale = absx;
  } else {
    s = absx / scale;
    b_y_tmp += s * s;
  }
  absx = params[2] * u[2] + x[13];
  b_y_tmp = scale * muDoubleScalarSqrt(b_y_tmp);
  for (eint = 0; eint < 3; eint++) {
    b_C_nb[eint] = ((C_nb[eint] * w_b_idx_0 + C_nb[eint + 3] * w_b_idx_1) +
                    C_nb[eint + 6] * absx) +
                   gl[eint];
  }
  absx = x[4];
  s = x[5];
  scale = x[6];
  y_tmp = x[7];
  for (eint = 0; eint < 4; eint++) {
    normRowMatrix[eint] =
        ((a[eint] * absx + a[eint + 4] * s) + a[eint + 8] * scale) +
        a[eint + 12] * y_tmp;
  }
  memset(&x_next[0], 0, 11U * sizeof(real_T));
  c_x[0] = x[0] + params[6] * b_y_tmp;
  c_x[1] = x[1] + params[6] * (180.0 * x[8] /
                               (3.1415926535897931 * (x[3] + 6.3568E+6)));
  c_x[2] = x[2] + params[6] * (-180.0 * x[9] /
                               (3.1415926535897931 * (x[3] + 6.3781E+6) * b_x));
  c_x[3] = x[3] + params[6] * x[10];
  c_x[4] = normRowMatrix[0];
  c_x[5] = normRowMatrix[1];
  c_x[6] = normRowMatrix[2];
  c_x[7] = normRowMatrix[3];
  c_x[8] = x[8] + b_C_nb[0] * params[6];
  c_x[9] = x[9] + b_C_nb[1] * params[6];
  c_x[10] = x[10] + b_C_nb[2] * params[6];
  for (eint = 0; eint < 6; eint++) {
    x_next[eint + 11] = x[eint + 11];
    c_x[eint + 11] = 0.0;
  }
  for (eint = 0; eint < 17; eint++) {
    x_next[eint] += c_x[eint];
  }
}

/* End of code generation (pig_eucld_dynamics.c) */
