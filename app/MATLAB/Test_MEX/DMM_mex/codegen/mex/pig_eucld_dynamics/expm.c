/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * expm.c
 *
 * Code generation for function 'expm'
 *
 */

/* Include files */
#include "expm.h"
#include "eml_int_forloop_overflow_check.h"
#include "rt_nonfinite.h"
#include "warning.h"
#include "mwmathutil.h"
#include <string.h>

/* Variable Definitions */
static emlrtRSInfo g_emlrtRSI = {
    175,                       /* lineNo */
    "PadeApproximantOfDegree", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\matfun\\expm.m" /* pathName
                                                                        */
};

static emlrtRSInfo
    h_emlrtRSI =
        {
            67,        /* lineNo */
            "lusolve", /* fcnName */
            "C:\\Program "
            "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+"
            "internal\\lusolve.m" /* pathName */
};

static emlrtRSInfo
    i_emlrtRSI =
        {
            112,          /* lineNo */
            "lusolveNxN", /* fcnName */
            "C:\\Program "
            "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+"
            "internal\\lusolve.m" /* pathName */
};

static emlrtRSInfo
    j_emlrtRSI =
        {
            109,          /* lineNo */
            "lusolveNxN", /* fcnName */
            "C:\\Program "
            "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+"
            "internal\\lusolve.m" /* pathName */
};

static emlrtRSInfo
    k_emlrtRSI =
        {
            124,          /* lineNo */
            "InvAtimesX", /* fcnName */
            "C:\\Program "
            "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+"
            "internal\\lusolve.m" /* pathName */
};

static emlrtRSInfo l_emlrtRSI = {
    26,        /* lineNo */
    "xgetrfs", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "lapack\\xgetrfs.m" /* pathName */
};

static emlrtRSInfo m_emlrtRSI = {
    27,        /* lineNo */
    "xgetrfs", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "lapack\\xgetrfs.m" /* pathName */
};

static emlrtRSInfo n_emlrtRSI = {
    30,       /* lineNo */
    "xgetrf", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "lapack\\xgetrf.m" /* pathName */
};

static emlrtRSInfo o_emlrtRSI = {
    36,        /* lineNo */
    "xzgetrf", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "reflapack\\xzgetrf.m" /* pathName */
};

static emlrtRSInfo p_emlrtRSI = {
    50,        /* lineNo */
    "xzgetrf", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "reflapack\\xzgetrf.m" /* pathName */
};

static emlrtRSInfo q_emlrtRSI = {
    58,        /* lineNo */
    "xzgetrf", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "reflapack\\xzgetrf.m" /* pathName */
};

static emlrtRSInfo r_emlrtRSI = {
    23,       /* lineNo */
    "ixamax", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "blas\\ixamax.m" /* pathName */
};

static emlrtRSInfo s_emlrtRSI = {
    24,       /* lineNo */
    "ixamax", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "refblas\\ixamax.m" /* pathName */
};

static emlrtRSInfo t_emlrtRSI = {
    21,                               /* lineNo */
    "eml_int_forloop_overflow_check", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\lib\\matlab\\eml\\eml_int_forloop_"
    "overflow_check.m" /* pathName */
};

static emlrtRSInfo u_emlrtRSI = {
    45,      /* lineNo */
    "xgeru", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+blas\\xgeru."
    "m" /* pathName */
};

static emlrtRSInfo v_emlrtRSI =
    {
        45,     /* lineNo */
        "xger", /* fcnName */
        "C:\\Program "
        "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
        "blas\\xger.m" /* pathName */
};

static emlrtRSInfo w_emlrtRSI = {
    15,     /* lineNo */
    "xger", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "refblas\\xger.m" /* pathName */
};

static emlrtRSInfo x_emlrtRSI = {
    41,      /* lineNo */
    "xgerx", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "refblas\\xgerx.m" /* pathName */
};

static emlrtRSInfo y_emlrtRSI = {
    54,      /* lineNo */
    "xgerx", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "refblas\\xgerx.m" /* pathName */
};

static emlrtRSInfo ab_emlrtRSI = {
    18,       /* lineNo */
    "xgetrs", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "lapack\\xgetrs.m" /* pathName */
};

static emlrtRSInfo bb_emlrtRSI = {
    32,        /* lineNo */
    "xzgetrs", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "reflapack\\xzgetrs.m" /* pathName */
};

static emlrtRSInfo cb_emlrtRSI = {
    36,        /* lineNo */
    "xzgetrs", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "reflapack\\xzgetrs.m" /* pathName */
};

static emlrtRSInfo db_emlrtRSI = {
    59,      /* lineNo */
    "xtrsm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+blas\\xtrsm."
    "m" /* pathName */
};

static emlrtRSInfo eb_emlrtRSI = {
    71,      /* lineNo */
    "xtrsm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "refblas\\xtrsm.m" /* pathName */
};

static emlrtRSInfo fb_emlrtRSI = {
    51,      /* lineNo */
    "xtrsm", /* fcnName */
    "C:\\Program "
    "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+internal\\+"
    "refblas\\xtrsm.m" /* pathName */
};

static emlrtRSInfo
    gb_emlrtRSI =
        {
            90,              /* lineNo */
            "warn_singular", /* fcnName */
            "C:\\Program "
            "Files\\MATLAB\\R2021b\\toolbox\\eml\\eml\\+coder\\+"
            "internal\\lusolve.m" /* pathName */
};

/* Function Definitions */
void PadeApproximantOfDegree(const emlrtStack *sp, const real_T A[16],
                             uint8_T m, real_T F[16])
{
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack d_st;
  emlrtStack e_st;
  emlrtStack f_st;
  emlrtStack g_st;
  emlrtStack h_st;
  emlrtStack i_st;
  emlrtStack j_st;
  emlrtStack k_st;
  emlrtStack l_st;
  emlrtStack st;
  real_T A2[16];
  real_T A3[16];
  real_T A4[16];
  real_T V[16];
  real_T b_A4[16];
  real_T b_d;
  real_T d;
  real_T d1;
  real_T s;
  int32_T a;
  int32_T b_tmp;
  int32_T i;
  int32_T info;
  int32_T j;
  int32_T jBcol;
  int32_T jp1j;
  int32_T k;
  int32_T n;
  int8_T ipiv[4];
  int8_T b_i;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  d_st.prev = &c_st;
  d_st.tls = c_st.tls;
  e_st.prev = &d_st;
  e_st.tls = d_st.tls;
  f_st.prev = &e_st;
  f_st.tls = e_st.tls;
  g_st.prev = &f_st;
  g_st.tls = f_st.tls;
  h_st.prev = &g_st;
  h_st.tls = g_st.tls;
  i_st.prev = &h_st;
  i_st.tls = h_st.tls;
  j_st.prev = &i_st;
  j_st.tls = i_st.tls;
  k_st.prev = &j_st;
  k_st.tls = j_st.tls;
  l_st.prev = &k_st;
  l_st.tls = k_st.tls;
  for (b_tmp = 0; b_tmp < 4; b_tmp++) {
    for (n = 0; n < 4; n++) {
      jBcol = n << 2;
      A2[b_tmp + jBcol] = ((A[b_tmp] * A[jBcol] + A[b_tmp + 4] * A[jBcol + 1]) +
                           A[b_tmp + 8] * A[jBcol + 2]) +
                          A[b_tmp + 12] * A[jBcol + 3];
    }
  }
  if (m == 3) {
    memcpy(&F[0], &A2[0], 16U * sizeof(real_T));
    F[0] += 60.0;
    F[5] += 60.0;
    F[10] += 60.0;
    F[15] += 60.0;
    for (b_tmp = 0; b_tmp < 4; b_tmp++) {
      d = A[b_tmp];
      s = A[b_tmp + 4];
      b_d = A[b_tmp + 8];
      d1 = A[b_tmp + 12];
      for (n = 0; n < 4; n++) {
        jBcol = n << 2;
        b_A4[b_tmp + jBcol] =
            ((d * F[jBcol] + s * F[jBcol + 1]) + b_d * F[jBcol + 2]) +
            d1 * F[jBcol + 3];
      }
    }
    for (b_tmp = 0; b_tmp < 16; b_tmp++) {
      F[b_tmp] = b_A4[b_tmp];
      V[b_tmp] = 12.0 * A2[b_tmp];
    }
    d = 120.0;
  } else {
    for (b_tmp = 0; b_tmp < 4; b_tmp++) {
      for (n = 0; n < 4; n++) {
        jBcol = n << 2;
        A3[b_tmp + jBcol] =
            ((A2[b_tmp] * A2[jBcol] + A2[b_tmp + 4] * A2[jBcol + 1]) +
             A2[b_tmp + 8] * A2[jBcol + 2]) +
            A2[b_tmp + 12] * A2[jBcol + 3];
      }
    }
    if (m == 5) {
      for (b_tmp = 0; b_tmp < 16; b_tmp++) {
        F[b_tmp] = A3[b_tmp] + 420.0 * A2[b_tmp];
      }
      F[0] += 15120.0;
      F[5] += 15120.0;
      F[10] += 15120.0;
      F[15] += 15120.0;
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        d = A[b_tmp];
        s = A[b_tmp + 4];
        b_d = A[b_tmp + 8];
        d1 = A[b_tmp + 12];
        for (n = 0; n < 4; n++) {
          jBcol = n << 2;
          b_A4[b_tmp + jBcol] =
              ((d * F[jBcol] + s * F[jBcol + 1]) + b_d * F[jBcol + 2]) +
              d1 * F[jBcol + 3];
        }
      }
      for (b_tmp = 0; b_tmp < 16; b_tmp++) {
        F[b_tmp] = b_A4[b_tmp];
        V[b_tmp] = 30.0 * A3[b_tmp] + 3360.0 * A2[b_tmp];
      }
      d = 30240.0;
    } else {
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        d = A3[b_tmp];
        s = A3[b_tmp + 4];
        b_d = A3[b_tmp + 8];
        d1 = A3[b_tmp + 12];
        for (n = 0; n < 4; n++) {
          jBcol = n << 2;
          A4[b_tmp + jBcol] =
              ((d * A2[jBcol] + s * A2[jBcol + 1]) + b_d * A2[jBcol + 2]) +
              d1 * A2[jBcol + 3];
        }
      }
      if (m == 7) {
        for (b_tmp = 0; b_tmp < 16; b_tmp++) {
          F[b_tmp] = (A4[b_tmp] + 1512.0 * A3[b_tmp]) + 277200.0 * A2[b_tmp];
        }
        F[0] += 8.64864E+6;
        F[5] += 8.64864E+6;
        F[10] += 8.64864E+6;
        F[15] += 8.64864E+6;
        for (b_tmp = 0; b_tmp < 4; b_tmp++) {
          d = A[b_tmp];
          s = A[b_tmp + 4];
          b_d = A[b_tmp + 8];
          d1 = A[b_tmp + 12];
          for (n = 0; n < 4; n++) {
            jBcol = n << 2;
            b_A4[b_tmp + jBcol] =
                ((d * F[jBcol] + s * F[jBcol + 1]) + b_d * F[jBcol + 2]) +
                d1 * F[jBcol + 3];
          }
        }
        for (b_tmp = 0; b_tmp < 16; b_tmp++) {
          F[b_tmp] = b_A4[b_tmp];
          V[b_tmp] =
              (56.0 * A4[b_tmp] + 25200.0 * A3[b_tmp]) + 1.99584E+6 * A2[b_tmp];
        }
        d = 1.729728E+7;
      } else if (m == 9) {
        for (b_tmp = 0; b_tmp < 4; b_tmp++) {
          d = A4[b_tmp];
          s = A4[b_tmp + 4];
          b_d = A4[b_tmp + 8];
          d1 = A4[b_tmp + 12];
          for (n = 0; n < 4; n++) {
            jBcol = n << 2;
            V[b_tmp + jBcol] =
                ((d * A2[jBcol] + s * A2[jBcol + 1]) + b_d * A2[jBcol + 2]) +
                d1 * A2[jBcol + 3];
          }
        }
        for (b_tmp = 0; b_tmp < 16; b_tmp++) {
          F[b_tmp] =
              ((V[b_tmp] + 3960.0 * A4[b_tmp]) + 2.16216E+6 * A3[b_tmp]) +
              3.027024E+8 * A2[b_tmp];
        }
        F[0] += 8.8216128E+9;
        F[5] += 8.8216128E+9;
        F[10] += 8.8216128E+9;
        F[15] += 8.8216128E+9;
        for (b_tmp = 0; b_tmp < 4; b_tmp++) {
          d = A[b_tmp];
          s = A[b_tmp + 4];
          b_d = A[b_tmp + 8];
          d1 = A[b_tmp + 12];
          for (n = 0; n < 4; n++) {
            jBcol = n << 2;
            b_A4[b_tmp + jBcol] =
                ((d * F[jBcol] + s * F[jBcol + 1]) + b_d * F[jBcol + 2]) +
                d1 * F[jBcol + 3];
          }
        }
        for (b_tmp = 0; b_tmp < 16; b_tmp++) {
          F[b_tmp] = b_A4[b_tmp];
          V[b_tmp] = ((90.0 * V[b_tmp] + 110880.0 * A4[b_tmp]) +
                      3.027024E+7 * A3[b_tmp]) +
                     2.0756736E+9 * A2[b_tmp];
        }
        d = 1.76432256E+10;
      } else {
        for (b_tmp = 0; b_tmp < 16; b_tmp++) {
          d = A4[b_tmp];
          s = A3[b_tmp];
          b_d = A2[b_tmp];
          F[b_tmp] = (3.352212864E+10 * d + 1.05594705216E+13 * s) +
                     1.1873537964288E+15 * b_d;
          b_A4[b_tmp] = (d + 16380.0 * s) + 4.08408E+7 * b_d;
        }
        F[0] += 3.238237626624E+16;
        F[5] += 3.238237626624E+16;
        F[10] += 3.238237626624E+16;
        F[15] += 3.238237626624E+16;
        for (b_tmp = 0; b_tmp < 4; b_tmp++) {
          d = A4[b_tmp];
          s = A4[b_tmp + 4];
          b_d = A4[b_tmp + 8];
          d1 = A4[b_tmp + 12];
          for (n = 0; n < 4; n++) {
            jBcol = n << 2;
            jp1j = b_tmp + jBcol;
            V[jp1j] = (((d * b_A4[jBcol] + s * b_A4[jBcol + 1]) +
                        b_d * b_A4[jBcol + 2]) +
                       d1 * b_A4[jBcol + 3]) +
                      F[jp1j];
          }
        }
        for (b_tmp = 0; b_tmp < 4; b_tmp++) {
          d = A[b_tmp];
          s = A[b_tmp + 4];
          b_d = A[b_tmp + 8];
          d1 = A[b_tmp + 12];
          for (n = 0; n < 4; n++) {
            jBcol = n << 2;
            F[b_tmp + jBcol] =
                ((d * V[jBcol] + s * V[jBcol + 1]) + b_d * V[jBcol + 2]) +
                d1 * V[jBcol + 3];
          }
        }
        for (b_tmp = 0; b_tmp < 16; b_tmp++) {
          b_A4[b_tmp] = (182.0 * A4[b_tmp] + 960960.0 * A3[b_tmp]) +
                        1.32324192E+9 * A2[b_tmp];
        }
        for (b_tmp = 0; b_tmp < 4; b_tmp++) {
          for (n = 0; n < 4; n++) {
            jBcol = n << 2;
            jp1j = b_tmp + jBcol;
            V[jp1j] = (((((A4[b_tmp] * b_A4[jBcol] +
                           A4[b_tmp + 4] * b_A4[jBcol + 1]) +
                          A4[b_tmp + 8] * b_A4[jBcol + 2]) +
                         A4[b_tmp + 12] * b_A4[jBcol + 3]) +
                        6.704425728E+11 * A4[jp1j]) +
                       1.29060195264E+14 * A3[jp1j]) +
                      7.7717703038976E+15 * A2[jp1j];
          }
        }
        d = 6.476475253248E+16;
      }
    }
  }
  V[0] += d;
  V[5] += d;
  V[10] += d;
  V[15] += d;
  for (k = 0; k < 16; k++) {
    d = F[k];
    V[k] -= d;
    d *= 2.0;
    F[k] = d;
  }
  st.site = &g_emlrtRSI;
  b_st.site = &h_emlrtRSI;
  c_st.site = &j_emlrtRSI;
  d_st.site = &k_emlrtRSI;
  e_st.site = &l_emlrtRSI;
  f_st.site = &n_emlrtRSI;
  ipiv[0] = 1;
  ipiv[1] = 2;
  ipiv[2] = 3;
  ipiv[3] = 4;
  info = 0;
  for (j = 0; j < 3; j++) {
    b_tmp = j * 5;
    jp1j = b_tmp + 2;
    n = 4 - j;
    g_st.site = &o_emlrtRSI;
    h_st.site = &r_emlrtRSI;
    a = 0;
    d = muDoubleScalarAbs(V[b_tmp]);
    i_st.site = &s_emlrtRSI;
    for (k = 2; k <= n; k++) {
      s = muDoubleScalarAbs(V[(b_tmp + k) - 1]);
      if (s > d) {
        a = k - 1;
        d = s;
      }
    }
    if (V[b_tmp + a] != 0.0) {
      if (a != 0) {
        jBcol = j + a;
        ipiv[j] = (int8_T)(jBcol + 1);
        d = V[j];
        V[j] = V[jBcol];
        V[jBcol] = d;
        d = V[j + 4];
        V[j + 4] = V[jBcol + 4];
        V[jBcol + 4] = d;
        d = V[j + 8];
        V[j + 8] = V[jBcol + 8];
        V[jBcol + 8] = d;
        d = V[j + 12];
        V[j + 12] = V[jBcol + 12];
        V[jBcol + 12] = d;
      }
      jBcol = (b_tmp - j) + 4;
      g_st.site = &p_emlrtRSI;
      for (i = jp1j; i <= jBcol; i++) {
        V[i - 1] /= V[b_tmp];
      }
    } else {
      info = j + 1;
    }
    n = 2 - j;
    g_st.site = &q_emlrtRSI;
    h_st.site = &u_emlrtRSI;
    i_st.site = &v_emlrtRSI;
    j_st.site = &w_emlrtRSI;
    jp1j = b_tmp + 6;
    k_st.site = &x_emlrtRSI;
    for (a = 0; a <= n; a++) {
      d = V[(b_tmp + (a << 2)) + 4];
      if (d != 0.0) {
        jBcol = (jp1j - j) + 2;
        k_st.site = &y_emlrtRSI;
        if ((jp1j <= jBcol) && (jBcol > 2147483646)) {
          l_st.site = &t_emlrtRSI;
          check_forloop_overflow_error(&l_st);
        }
        for (k = jp1j; k <= jBcol; k++) {
          V[k - 1] += V[((b_tmp + k) - jp1j) + 1] * -d;
        }
      }
      jp1j += 4;
    }
  }
  if ((info == 0) && (!(V[15] != 0.0))) {
    info = 4;
  }
  e_st.site = &m_emlrtRSI;
  f_st.site = &ab_emlrtRSI;
  for (i = 0; i < 3; i++) {
    b_i = ipiv[i];
    if (b_i != i + 1) {
      d = F[i];
      F[i] = F[b_i - 1];
      F[b_i - 1] = d;
      d = F[i + 4];
      F[i + 4] = F[b_i + 3];
      F[b_i + 3] = d;
      d = F[i + 8];
      F[i + 8] = F[b_i + 7];
      F[b_i + 7] = d;
      d = F[i + 12];
      F[i + 12] = F[b_i + 11];
      F[b_i + 11] = d;
    }
  }
  g_st.site = &bb_emlrtRSI;
  h_st.site = &db_emlrtRSI;
  for (j = 0; j < 4; j++) {
    jBcol = j << 2;
    for (k = 0; k < 4; k++) {
      jp1j = k << 2;
      b_tmp = k + jBcol;
      if (F[b_tmp] != 0.0) {
        a = k + 2;
        i_st.site = &eb_emlrtRSI;
        for (i = a; i < 5; i++) {
          n = (i + jBcol) - 1;
          F[n] -= F[b_tmp] * V[(i + jp1j) - 1];
        }
      }
    }
  }
  g_st.site = &cb_emlrtRSI;
  h_st.site = &db_emlrtRSI;
  for (j = 0; j < 4; j++) {
    jBcol = j << 2;
    for (k = 3; k >= 0; k--) {
      jp1j = k << 2;
      b_tmp = k + jBcol;
      d = F[b_tmp];
      if (d != 0.0) {
        F[b_tmp] = d / V[k + jp1j];
        i_st.site = &fb_emlrtRSI;
        for (i = 0; i < k; i++) {
          n = i + jBcol;
          F[n] -= F[b_tmp] * V[i + jp1j];
        }
      }
    }
  }
  if (info > 0) {
    c_st.site = &i_emlrtRSI;
    d_st.site = &gb_emlrtRSI;
    warning(&d_st);
  }
  F[0]++;
  F[5]++;
  F[10]++;
  F[15]++;
}

/* End of code generation (expm.c) */
