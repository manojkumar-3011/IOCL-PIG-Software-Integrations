/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * pig_dynamics.c
 *
 * Code generation for function 'pig_dynamics'
 *
 */

/* Include files */
#include "pig_dynamics.h"
#include "cosd.h"
#include "expm.h"
#include "pig_dynamics_data.h"
#include "rotx.h"
#include "rt_nonfinite.h"
#include "sind.h"
#include "sumMatrixIncludeNaN.h"
#include "mwmathutil.h"
#include <math.h>
#include <string.h>

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = {
    22,             /* lineNo */
    "pig_dynamics", /* fcnName */
    "F:\\Academic\\Dropbox\\Recent\\WorkQC\\Experiments for "
    "transfer\\FSP_ver0_speed\\Test_MEX\\DMM_mex\\pig_dynamics.m" /* pathName */
};

static emlrtRSInfo b_emlrtRSI = {
    31,             /* lineNo */
    "pig_dynamics", /* fcnName */
    "F:\\Academic\\Dropbox\\Recent\\WorkQC\\Experiments for "
    "transfer\\FSP_ver0_speed\\Test_MEX\\DMM_mex\\pig_dynamics.m" /* pathName */
};

static emlrtRSInfo c_emlrtRSI = {
    32,             /* lineNo */
    "pig_dynamics", /* fcnName */
    "F:\\Academic\\Dropbox\\Recent\\WorkQC\\Experiments for "
    "transfer\\FSP_ver0_speed\\Test_MEX\\DMM_mex\\pig_dynamics.m" /* pathName */
};

static emlrtRSInfo d_emlrtRSI = {
    51,     /* lineNo */
    "expm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo e_emlrtRSI = {
    56,     /* lineNo */
    "expm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo f_emlrtRSI = {
    60,     /* lineNo */
    "expm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo g_emlrtRSI = {
    61,     /* lineNo */
    "expm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo ib_emlrtRSI = {
    17,     /* lineNo */
    "log2", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\elfun\\log2.m" /* pathName
                                                                       */
};

static emlrtRSInfo lb_emlrtRSI = {
    12,     /* lineNo */
    "pow2", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\elfun\\pow2.m" /* pathName
                                                                       */
};

static emlrtRSInfo ob_emlrtRSI =
    {
        71,      /* lineNo */
        "power", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\ops\\power.m" /* pathName
                                                                          */
};

static emlrtRSInfo pb_emlrtRSI = {
    31,     /* lineNo */
    "roty", /* fcnName */
    "C:\\Program Files\\MATLAB\\R2021b\\toolbox\\phased\\phased\\roty.m" /* pathName
                                                                          */
};

static emlrtRSInfo tb_emlrtRSI =
    {
        32,          /* lineNo */
        "quat2rotm", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\quat2rot"
        "m.m" /* pathName */
};

static emlrtRSInfo ub_emlrtRSI =
    {
        43,          /* lineNo */
        "quat2rotm", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\quat2rot"
        "m.m" /* pathName */
};

static emlrtRSInfo vb_emlrtRSI =
    {
        44,          /* lineNo */
        "quat2rotm", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\quat2rot"
        "m.m" /* pathName */
};

static emlrtRSInfo wb_emlrtRSI =
    {
        45,          /* lineNo */
        "quat2rotm", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\shared\\robotics\\robotutils\\quat2rot"
        "m.m" /* pathName */
};

static emlrtRSInfo xb_emlrtRSI = {
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

static emlrtRTEInfo d_emlrtRTEI = {
    13,     /* lineNo */
    9,      /* colNo */
    "sqrt", /* fName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\elfun\\sqrt.m" /* pName
                                                                       */
};

/* Function Definitions */
void pig_dynamics(const emlrtStack *sp, real_T t, const real_T x[17],
                  const real_T u[6], const real_T params[8], real_T x_next[17])
{
  static const real_T theta[5] = {0.01495585217958292, 0.253939833006323,
                                  0.95041789961629319, 2.097847961257068,
                                  5.3719203511481517};
  static const real_T dv[3] = {0.0, 0.0, -9.81};
  static const uint8_T uv[5] = {3U, 5U, 7U, 9U, 13U};
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack d_st;
  emlrtStack st;
  real_T b_x[17];
  real_T a[16];
  real_T y[16];
  real_T Sx_n_omega_ie[9];
  real_T b[9];
  real_T b_b[9];
  real_T c_b[9];
  real_T c_rotmat_tmp[9];
  real_T tempR[9];
  real_T normRowMatrix[4];
  real_T d_rotmat_tmp[3];
  real_T e_rotmat_tmp[3];
  real_T w[3];
  real_T w_b[3];
  real_T G_func_tmp;
  real_T b_rotmat_tmp;
  real_T b_t;
  real_T b_y_tmp;
  real_T normA;
  real_T rotmat_tmp;
  real_T s;
  real_T tempR_tmp;
  real_T v_scl_idx_0;
  real_T v_scl_idx_1;
  real_T v_scl_idx_2;
  real_T y_tmp;
  int32_T eint;
  int32_T i;
  int32_T i1;
  int32_T j;
  int32_T s_tmp;
  int8_T n;
  boolean_T exitg1;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  d_st.prev = &c_st;
  d_st.tls = c_st.tls;
  /*  equatorial (Wikipedia)  */
  /*  polar (Wikipedia)  */
  /*  manifold is default  */
  /*  earth rotation is default value  */
  /*  radians per second [=7.292115e-5*180/pi*86400 = 360.9856]  */
  /*  o <--x(1) | p <--x(2:4) | q <--x(5:8) | v <--x(9:11) | bs <--x(12:17) [+]
   * imu_a <--u(1:3) | imu_w <--u(4:6)   */
  v_scl_idx_0 = params[7] * x[8];
  v_scl_idx_1 = params[7] * x[9];
  v_scl_idx_2 = params[7] * x[10];
  G_func_tmp = x[1];
  b_cosd(&G_func_tmp);
  w_b[0] = params[3] * u[3] + x[14];
  w_b[1] = params[4] * u[4] + x[15];
  w_b[2] = params[5] * u[5] + x[16];
  y[0] = 0.0 * params[6];
  normA = 0.5 * -w_b[0] * params[6];
  y[4] = normA;
  s = 0.5 * -w_b[1] * params[6];
  y[8] = s;
  b_t = 0.5 * -w_b[2] * params[6];
  y[12] = b_t;
  y_tmp = 0.5 * w_b[0] * params[6];
  y[1] = y_tmp;
  y[5] = 0.0 * params[6];
  b_y_tmp = 0.5 * w_b[2] * params[6];
  y[9] = b_y_tmp;
  y[13] = s;
  s = 0.5 * w_b[1] * params[6];
  y[2] = s;
  y[6] = b_t;
  y[10] = 0.0 * params[6];
  y[14] = y_tmp;
  y[3] = b_y_tmp;
  y[7] = s;
  y[11] = normA;
  y[15] = 0.0 * params[6];
  st.site = &emlrtRSI;
  normA = 0.0;
  j = 0;
  exitg1 = false;
  while ((!exitg1) && (j < 4)) {
    s_tmp = j << 2;
    s = ((muDoubleScalarAbs(y[s_tmp]) + muDoubleScalarAbs(y[s_tmp + 1])) +
         muDoubleScalarAbs(y[s_tmp + 2])) +
        muDoubleScalarAbs(y[s_tmp + 3]);
    if (muDoubleScalarIsNaN(s)) {
      normA = rtNaN;
      exitg1 = true;
    } else {
      if (s > normA) {
        normA = s;
      }
      j++;
    }
  }
  if (normA <= 5.3719203511481517) {
    s_tmp = 0;
    exitg1 = false;
    while ((!exitg1) && (s_tmp < 5)) {
      if (normA <= theta[s_tmp]) {
        b_st.site = &d_emlrtRSI;
        PadeApproximantOfDegree(&b_st, y, uv[s_tmp], a);
        exitg1 = true;
      } else {
        s_tmp++;
      }
    }
  } else {
    b_st.site = &e_emlrtRSI;
    b_t = normA / 5.3719203511481517;
    c_st.site = &ib_emlrtRSI;
    if ((!muDoubleScalarIsInf(b_t)) && (!muDoubleScalarIsNaN(b_t))) {
      b_t = frexp(b_t, &eint);
    } else {
      eint = 0;
    }
    s = eint;
    if (b_t == 0.5) {
      s = (real_T)eint - 1.0;
    }
    b_st.site = &f_emlrtRSI;
    c_st.site = &lb_emlrtRSI;
    b_y_tmp = muDoubleScalarPower(2.0, s);
    for (eint = 0; eint < 16; eint++) {
      y[eint] /= b_y_tmp;
    }
    b_st.site = &g_emlrtRSI;
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
  normA = x[1];
  b_sind(&normA);
  w_b[0] = 7.292115E-5 * G_func_tmp;
  w_b[2] = 7.292115E-5 * normA;
  if (muDoubleScalarIsInf(x[1]) || muDoubleScalarIsNaN(x[1])) {
    b_t = rtNaN;
  } else {
    b_t = muDoubleScalarRem(x[1], 360.0);
    normA = muDoubleScalarAbs(b_t);
    if (normA > 180.0) {
      if (b_t > 0.0) {
        b_t -= 360.0;
      } else {
        b_t += 360.0;
      }
      normA = muDoubleScalarAbs(b_t);
    }
    if (normA <= 45.0) {
      b_t *= 0.017453292519943295;
      n = 0;
    } else if (normA <= 135.0) {
      if (b_t > 0.0) {
        b_t = 0.017453292519943295 * (b_t - 90.0);
        n = 1;
      } else {
        b_t = 0.017453292519943295 * (b_t + 90.0);
        n = -1;
      }
    } else if (b_t > 0.0) {
      b_t = 0.017453292519943295 * (b_t - 180.0);
      n = 2;
    } else {
      b_t = 0.017453292519943295 * (b_t + 180.0);
      n = -2;
    }
    b_t = muDoubleScalarTan(b_t);
    if ((n == 1) || (n == -1)) {
      normA = 1.0 / b_t;
      b_t = -(1.0 / b_t);
      if (muDoubleScalarIsInf(b_t) && (n == 1)) {
        b_t = normA;
      }
    }
  }
  w[0] = 2.0 * w_b[0] + -x[9] / (x[3] + 6.3781E+6);
  w[1] = x[8] / (x[3] + 6.3568E+6);
  w[2] = 2.0 * w_b[2] + -x[9] * b_t / (x[3] + 6.3781E+6);
  Sx_n_omega_ie[0] = 0.0;
  Sx_n_omega_ie[3] = -w_b[2];
  Sx_n_omega_ie[6] = 0.0;
  Sx_n_omega_ie[1] = w_b[2];
  Sx_n_omega_ie[4] = 0.0;
  Sx_n_omega_ie[7] = -w_b[0];
  Sx_n_omega_ie[2] = -0.0;
  Sx_n_omega_ie[5] = w_b[0];
  Sx_n_omega_ie[8] = 0.0;
  st.site = &b_emlrtRSI;
  b_st.site = &pb_emlrtRSI;
  c_st.site = &qb_emlrtRSI;
  d_st.site = &rb_emlrtRSI;
  if (muDoubleScalarIsInf(-x[1]) || muDoubleScalarIsNaN(-x[1])) {
    emlrtErrorWithMessageIdR2018a(
        &d_st, &b_emlrtRTEI, "Coder:toolbox:ValidateattributesexpectedFinite",
        "MATLAB:roty:expectedFinite", 3, 4, 4, "BETA");
  }
  d_st.site = &rb_emlrtRSI;
  if (muDoubleScalarIsNaN(-x[1])) {
    emlrtErrorWithMessageIdR2018a(
        &d_st, &c_emlrtRTEI, "Coder:toolbox:ValidateattributesexpectedNonNaN",
        "MATLAB:roty:expectedNonNaN", 3, 4, 4, "BETA");
  }
  rotmat_tmp = -x[1];
  b_sind(&rotmat_tmp);
  b_rotmat_tmp = -x[1];
  b_cosd(&b_rotmat_tmp);
  st.site = &b_emlrtRSI;
  rotx(&st, -x[2], b);
  st.site = &c_emlrtRSI;
  rotx(&st, -t * 7.292115E-5 * 180.0 / 3.1415926535897931, b_b);
  st.site = &c_emlrtRSI;
  b_st.site = &tb_emlrtRSI;
  normRowMatrix[0] = muDoubleScalarPower(x[4], 2.0);
  normRowMatrix[1] = muDoubleScalarPower(x[5], 2.0);
  normRowMatrix[2] = muDoubleScalarPower(x[6], 2.0);
  normRowMatrix[3] = muDoubleScalarPower(x[7], 2.0);
  c_st.site = &xb_emlrtRSI;
  b_t = sumColumnB(normRowMatrix);
  c_st.site = &xb_emlrtRSI;
  if (b_t < 0.0) {
    emlrtErrorWithMessageIdR2018a(
        &c_st, &d_emlrtRTEI, "Coder:toolbox:ElFunDomainError",
        "Coder:toolbox:ElFunDomainError", 3, 4, 4, "sqrt");
  }
  b_t = muDoubleScalarSqrt(b_t);
  normA = 1.0 / b_t;
  normRowMatrix[0] = x[4] * normA;
  normRowMatrix[1] = x[5] * normA;
  normRowMatrix[2] = x[6] * normA;
  normRowMatrix[3] = x[7] * normA;
  b_st.site = &ub_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  b_st.site = &ub_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  b_st.site = &vb_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  b_st.site = &vb_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  b_st.site = &wb_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  b_st.site = &wb_emlrtRSI;
  c_st.site = &ob_emlrtRSI;
  normA = normRowMatrix[3] * normRowMatrix[3];
  s = normRowMatrix[2] * normRowMatrix[2];
  tempR[0] = 1.0 - 2.0 * (s + normA);
  y_tmp = normRowMatrix[1] * normRowMatrix[2];
  b_y_tmp = normRowMatrix[0] * normRowMatrix[3];
  tempR[1] = 2.0 * (y_tmp - b_y_tmp);
  b_t = normRowMatrix[1] * normRowMatrix[3];
  tempR_tmp = normRowMatrix[0] * normRowMatrix[2];
  tempR[2] = 2.0 * (b_t + tempR_tmp);
  tempR[3] = 2.0 * (y_tmp + b_y_tmp);
  y_tmp = normRowMatrix[1] * normRowMatrix[1];
  tempR[4] = 1.0 - 2.0 * (y_tmp + normA);
  normA = normRowMatrix[2] * normRowMatrix[3];
  b_y_tmp = normRowMatrix[0] * normRowMatrix[1];
  tempR[5] = 2.0 * (normA - b_y_tmp);
  tempR[6] = 2.0 * (b_t - tempR_tmp);
  tempR[7] = 2.0 * (normA + b_y_tmp);
  tempR[8] = 1.0 - 2.0 * (y_tmp + s);
  memcpy(&c_b[0], &tempR[0], 9U * sizeof(real_T));
  for (eint = 0; eint < 3; eint++) {
    s_tmp = 3 * eint;
    c_b[eint] = tempR[s_tmp];
    c_b[eint + 3] = tempR[s_tmp + 1];
    c_b[eint + 6] = tempR[s_tmp + 2];
  }
  /*  eul2rotm(flip(omega_ie(p)')*t) */
  normA = 3.3121686421112381E-170;
  s = muDoubleScalarAbs(v_scl_idx_0);
  if (s > 3.3121686421112381E-170) {
    b_y_tmp = 1.0;
    normA = s;
  } else {
    b_t = s / 3.3121686421112381E-170;
    b_y_tmp = b_t * b_t;
  }
  s = muDoubleScalarAbs(v_scl_idx_1);
  if (s > normA) {
    b_t = normA / s;
    b_y_tmp = b_y_tmp * b_t * b_t + 1.0;
    normA = s;
  } else {
    b_t = s / normA;
    b_y_tmp += b_t * b_t;
  }
  s = muDoubleScalarAbs(v_scl_idx_2);
  if (s > normA) {
    b_t = normA / s;
    b_y_tmp = b_y_tmp * b_t * b_t + 1.0;
    normA = s;
  } else {
    b_t = s / normA;
    b_y_tmp += b_t * b_t;
  }
  b_y_tmp = normA * muDoubleScalarSqrt(b_y_tmp);
  /*  [not needed] /norm(q_gen(q,bs,imu_w));  */
  tempR[0] = b_rotmat_tmp;
  tempR[3] = 0.0;
  tempR[6] = rotmat_tmp;
  tempR[1] = 0.0;
  tempR[4] = 1.0;
  tempR[7] = 0.0;
  tempR[2] = -rotmat_tmp;
  tempR[5] = 0.0;
  tempR[8] = b_rotmat_tmp;
  for (eint = 0; eint < 3; eint++) {
    normA = tempR[eint];
    s = tempR[eint + 3];
    b_t = tempR[eint + 6];
    for (i = 0; i < 3; i++) {
      c_rotmat_tmp[eint + 3 * i] =
          (normA * b[3 * i] + s * b[3 * i + 1]) + b_t * b[3 * i + 2];
    }
    normA = c_rotmat_tmp[eint];
    s = c_rotmat_tmp[eint + 3];
    b_t = c_rotmat_tmp[eint + 6];
    for (i = 0; i < 3; i++) {
      tempR[eint + 3 * i] =
          (normA * b_b[3 * i] + s * b_b[3 * i + 1]) + b_t * b_b[3 * i + 2];
    }
    normA = tempR[eint];
    s = tempR[eint + 3];
    b_t = tempR[eint + 6];
    for (i = 0; i < 3; i++) {
      c_rotmat_tmp[eint + 3 * i] =
          (normA * c_b[3 * i] + s * c_b[3 * i + 1]) + b_t * c_b[3 * i + 2];
    }
    w_b[eint] = params[eint] * u[eint] + x[eint + 11];
  }
  b[0] = 0.0;
  b[3] = -w[2];
  b[6] = w[1];
  b[1] = w[2];
  b[4] = 0.0;
  b[7] = -w[0];
  b[2] = -w[1];
  b[5] = w[0];
  b[8] = 0.0;
  normA = w_b[0];
  s = w_b[1];
  b_t = w_b[2];
  for (eint = 0; eint < 3; eint++) {
    d_rotmat_tmp[eint] =
        (c_rotmat_tmp[eint] * normA + c_rotmat_tmp[eint + 3] * s) +
        c_rotmat_tmp[eint + 6] * b_t;
  }
  normA = x[8];
  s = x[9];
  b_t = x[10];
  for (eint = 0; eint < 3; eint++) {
    w_b[eint] = (b[eint] * normA + b[eint + 3] * s) + b[eint + 6] * b_t;
  }
  for (eint = 0; eint < 9; eint++) {
    b[eint] = -Sx_n_omega_ie[eint];
  }
  w[0] = 0.0;
  w[1] = 0.0;
  w[2] = x[3] + 6.3781E+6;
  for (eint = 0; eint < 3; eint++) {
    normA = 0.0;
    s = b[eint];
    b_t = b[eint + 3];
    y_tmp = b[eint + 6];
    for (i = 0; i < 3; i++) {
      normA += ((s * Sx_n_omega_ie[3 * i] + b_t * Sx_n_omega_ie[3 * i + 1]) +
                y_tmp * Sx_n_omega_ie[3 * i + 2]) *
               w[i];
    }
    e_rotmat_tmp[eint] = (d_rotmat_tmp[eint] - w_b[eint]) + (normA + dv[eint]);
  }
  normA = x[4];
  s = x[5];
  b_t = x[6];
  y_tmp = x[7];
  for (eint = 0; eint < 4; eint++) {
    normRowMatrix[eint] =
        ((a[eint] * normA + a[eint + 4] * s) + a[eint + 8] * b_t) +
        a[eint + 12] * y_tmp;
  }
  memset(&x_next[0], 0, 11U * sizeof(real_T));
  b_x[0] = x[0] + params[6] * b_y_tmp;
  b_x[1] = x[1] + params[6] * (180.0 * v_scl_idx_0 /
                               (3.1415926535897931 * (x[3] + 6.3568E+6)));
  b_x[2] = x[2] +
           params[6] * (-180.0 * v_scl_idx_1 /
                        (3.1415926535897931 * (x[3] + 6.3781E+6) * G_func_tmp));
  b_x[3] = x[3] + v_scl_idx_2 * params[6];
  b_x[4] = normRowMatrix[0];
  b_x[5] = normRowMatrix[1];
  b_x[6] = normRowMatrix[2];
  b_x[7] = normRowMatrix[3];
  b_x[8] = x[8] + e_rotmat_tmp[0] * params[6];
  b_x[9] = x[9] + e_rotmat_tmp[1] * params[6];
  b_x[10] = x[10] + e_rotmat_tmp[2] * params[6];
  for (eint = 0; eint < 6; eint++) {
    x_next[eint + 11] = x[eint + 11];
    b_x[eint + 11] = 0.0;
  }
  for (eint = 0; eint < 17; eint++) {
    x_next[eint] += b_x[eint];
  }
}

/* End of code generation (pig_dynamics.c) */
