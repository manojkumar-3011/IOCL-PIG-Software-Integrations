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
#include "log2.h"
#include "norm.h"
#include "rt_nonfinite.h"
#include "warning.h"
#include "lapacke.h"
#include "mwmathutil.h"
#include <emmintrin.h>
#include <math.h>
#include <stddef.h>
#include <string.h>

/* Variable Definitions */
static emlrtRSInfo j_emlrtRSI = {
    71,                                                           /* lineNo */
    "power",                                                      /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/ops/power.m" /* pathName */
};

static emlrtRSInfo m_emlrtRSI = {
    23,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo n_emlrtRSI = {
    36,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo o_emlrtRSI = {
    38,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo p_emlrtRSI = {
    39,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo q_emlrtRSI = {
    40,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo r_emlrtRSI = {
    41,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo s_emlrtRSI = {
    48,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo t_emlrtRSI = {
    50,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo u_emlrtRSI = {
    57,     /* lineNo */
    "expm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo v_emlrtRSI = {
    10,        /* lineNo */
    "xsyheev", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+lapack/"
    "xsyheev.m" /* pathName */
};

static emlrtRSInfo w_emlrtRSI = {
    61,              /* lineNo */
    "ceval_xsyheev", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+lapack/"
    "xsyheev.m" /* pathName */
};

static emlrtRSInfo x_emlrtRSI = {
    20,                               /* lineNo */
    "eml_int_forloop_overflow_check", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/eml/"
    "eml_int_forloop_overflow_check.m" /* pathName */
};

static emlrtRSInfo ab_emlrtRSI = {
    63,              /* lineNo */
    "getExpmParams", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo bb_emlrtRSI = {
    104,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo cb_emlrtRSI = {
    105,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo db_emlrtRSI = {
    107,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo eb_emlrtRSI = {
    112,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo fb_emlrtRSI = {
    117,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo gb_emlrtRSI = {
    120,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo hb_emlrtRSI = {
    125,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo ib_emlrtRSI = {
    130,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo jb_emlrtRSI = {
    133,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo kb_emlrtRSI = {
    134,                  /* lineNo */
    "getExpmParamsBasic", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo mb_emlrtRSI = {
    325,   /* lineNo */
    "ell", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo nb_emlrtRSI = {
    267,                 /* lineNo */
    "padeApproximation", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pathName
                                                                     */
};

static emlrtRSInfo ob_emlrtRSI = {
    67,        /* lineNo */
    "lusolve", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/lusolve.m" /* pathName
                                                                           */
};

static emlrtRSInfo pb_emlrtRSI = {
    109,          /* lineNo */
    "lusolveNxN", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/lusolve.m" /* pathName
                                                                           */
};

static emlrtRSInfo qb_emlrtRSI = {
    112,          /* lineNo */
    "lusolveNxN", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/lusolve.m" /* pathName
                                                                           */
};

static emlrtRSInfo rb_emlrtRSI = {
    124,          /* lineNo */
    "InvAtimesX", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/lusolve.m" /* pathName
                                                                           */
};

static emlrtRSInfo sb_emlrtRSI = {
    26,        /* lineNo */
    "xgetrfs", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+lapack/"
    "xgetrfs.m" /* pathName */
};

static emlrtRSInfo tb_emlrtRSI =
    {
        30,       /* lineNo */
        "xgetrf", /* fcnName */
        "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+lapack/"
        "xgetrf.m" /* pathName */
};

static emlrtRSInfo ub_emlrtRSI = {
    55,        /* lineNo */
    "xzgetrf", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+reflapack/"
    "xzgetrf.m" /* pathName */
};

static emlrtRSInfo vb_emlrtRSI = {
    63,        /* lineNo */
    "xzgetrf", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+reflapack/"
    "xzgetrf.m" /* pathName */
};

static emlrtRSInfo wb_emlrtRSI =
    {
        45,      /* lineNo */
        "xgeru", /* fcnName */
        "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+blas/"
        "xgeru.m" /* pathName */
};

static emlrtRSInfo
    xb_emlrtRSI =
        {
            45,     /* lineNo */
            "xger", /* fcnName */
            "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+blas/"
            "xger.m" /* pathName */
};

static emlrtRSInfo yb_emlrtRSI =
    {
        15,     /* lineNo */
        "xger", /* fcnName */
        "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+refblas/"
        "xger.m" /* pathName */
};

static emlrtRSInfo ac_emlrtRSI =
    {
        54,      /* lineNo */
        "xgerx", /* fcnName */
        "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+refblas/"
        "xgerx.m" /* pathName */
};

static emlrtRSInfo bc_emlrtRSI = {
    90,              /* lineNo */
    "warn_singular", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/lusolve.m" /* pathName
                                                                           */
};

static emlrtRTEInfo b_emlrtRTEI = {
    53,                                                             /* lineNo */
    13,                                                             /* colNo */
    "expm",                                                         /* fName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/matfun/expm.m" /* pName */
};

static emlrtRTEInfo c_emlrtRTEI = {
    45,          /* lineNo */
    13,          /* colNo */
    "infocheck", /* fName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+lapack/"
    "infocheck.m" /* pName */
};

static emlrtRTEInfo d_emlrtRTEI = {
    48,          /* lineNo */
    13,          /* colNo */
    "infocheck", /* fName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/eml/+coder/+internal/+lapack/"
    "infocheck.m" /* pName */
};

static emlrtRTEInfo e_emlrtRTEI = {
    82,                                                           /* lineNo */
    5,                                                            /* colNo */
    "fltpower",                                                   /* fName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/ops/power.m" /* pName */
};

/* Function Declarations */
static int32_T getExpmParams(const emlrtStack *sp, const real_T A[16],
                             real_T A2[16], real_T A4[16], real_T A6[16],
                             real_T *s);

static void padeApproximation(const emlrtStack *sp, const real_T A[16],
                              const real_T A2[16], const real_T A4[16],
                              const real_T A6[16], int32_T m, real_T F[16]);

static void recomputeBlockDiag(const real_T A[16], real_T F[16],
                               const int32_T blockFormat[3]);

/* Function Definitions */
static int32_T getExpmParams(const emlrtStack *sp, const real_T A[16],
                             real_T A2[16], real_T A4[16], real_T A6[16],
                             real_T *s)
{
  __m128d r;
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack st;
  real_T T[16];
  real_T aBuffer[16];
  real_T b_aBuffer[16];
  real_T b_cBuffer[16];
  real_T b_scaledT[16];
  real_T cBuffer[16];
  real_T scaledT[16];
  real_T dv[2];
  real_T dv1[2];
  real_T dv2[2];
  real_T dv3[2];
  real_T dv4[2];
  real_T a;
  real_T d;
  real_T d1;
  real_T d2;
  real_T d3;
  real_T d4;
  real_T d5;
  real_T d6;
  real_T d8;
  real_T eta1;
  real_T y;
  int32_T cBuffer_tmp;
  int32_T eint;
  int32_T i;
  int32_T i1;
  int32_T k;
  int32_T m;
  boolean_T guard1;
  boolean_T guard2;
  boolean_T guard3;
  boolean_T guard4;
  st.prev = sp;
  st.tls = sp->tls;
  st.site = &ab_emlrtRSI;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  *s = 0.0;
  for (i = 0; i < 4; i++) {
    for (i1 = 0; i1 < 4; i1++) {
      k = i1 << 2;
      A2[i + k] = ((A[i] * A[k] + A[i + 4] * A[k + 1]) + A[i + 8] * A[k + 2]) +
                  A[i + 12] * A[k + 3];
    }
  }
  for (i = 0; i < 4; i++) {
    for (i1 = 0; i1 < 4; i1++) {
      k = i1 << 2;
      A4[i + k] =
          ((A2[i] * A2[k] + A2[i + 4] * A2[k + 1]) + A2[i + 8] * A2[k + 2]) +
          A2[i + 12] * A2[k + 3];
    }
    a = A4[i];
    y = A4[i + 4];
    d = A4[i + 8];
    d1 = A4[i + 12];
    for (i1 = 0; i1 < 4; i1++) {
      k = i1 << 2;
      A6[i + k] =
          ((a * A2[k] + y * A2[k + 1]) + d * A2[k + 2]) + d1 * A2[k + 3];
    }
  }
  b_st.site = &bb_emlrtRSI;
  eta1 = b_norm(A4);
  c_st.site = &j_emlrtRSI;
  if (eta1 < 0.0) {
    emlrtErrorWithMessageIdR2018a(&c_st, &e_emlrtRTEI,
                                  "Coder:toolbox:power_domainError",
                                  "Coder:toolbox:power_domainError", 0);
  }
  b_st.site = &cb_emlrtRSI;
  a = b_norm(A6);
  c_st.site = &j_emlrtRSI;
  if (a < 0.0) {
    emlrtErrorWithMessageIdR2018a(&c_st, &e_emlrtRTEI,
                                  "Coder:toolbox:power_domainError",
                                  "Coder:toolbox:power_domainError", 0);
  }
  d6 = muDoubleScalarPower(a, 0.16666666666666666);
  eta1 = muDoubleScalarMax(muDoubleScalarPower(eta1, 0.25), d6);
  guard1 = false;
  guard2 = false;
  guard3 = false;
  guard4 = false;
  if (eta1 <= 0.01495585217958292) {
    b_st.site = &db_emlrtRSI;
    for (k = 0; k <= 14; k += 2) {
      dv[0] = muDoubleScalarAbs(A[k]);
      dv[1] = muDoubleScalarAbs(A[k + 1]);
      r = _mm_loadu_pd(&dv[0]);
      _mm_storeu_pd(&scaledT[k],
                    _mm_mul_pd(_mm_set1_pd(0.19285012468241128), r));
    }
    for (i = 0; i < 4; i++) {
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        aBuffer[i + k] =
            ((scaledT[i] * scaledT[k] + scaledT[i + 4] * scaledT[k + 1]) +
             scaledT[i + 8] * scaledT[k + 2]) +
            scaledT[i + 12] * scaledT[k + 3];
      }
    }
    for (i = 0; i < 4; i++) {
      a = scaledT[i];
      y = scaledT[i + 4];
      d = scaledT[i + 8];
      d1 = scaledT[i + 12];
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        d2 = aBuffer[k];
        d3 = aBuffer[k + 1];
        d4 = aBuffer[k + 2];
        d5 = aBuffer[k + 3];
        k += i;
        b_aBuffer[k] =
            ((aBuffer[i] * d2 + aBuffer[i + 4] * d3) + aBuffer[i + 8] * d4) +
            aBuffer[i + 12] * d5;
        b_scaledT[k] = ((a * d2 + y * d3) + d * d4) + d1 * d5;
      }
    }
    for (i = 0; i < 4; i++) {
      a = b_scaledT[i];
      y = b_scaledT[i + 4];
      d = b_scaledT[i + 8];
      d1 = b_scaledT[i + 12];
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        scaledT[i + k] =
            ((a * b_aBuffer[k] + y * b_aBuffer[k + 1]) + d * b_aBuffer[k + 2]) +
            d1 * b_aBuffer[k + 3];
      }
    }
    c_st.site = &mb_emlrtRSI;
    a = b_log2(&c_st,
               2.0 * (b_norm(scaledT) / b_norm(A)) / 2.2204460492503131E-16) /
        6.0;
    if (muDoubleScalarMax(muDoubleScalarCeil(a), 0.0) == 0.0) {
      m = 3;
    } else {
      guard4 = true;
    }
  } else {
    guard4 = true;
  }
  if (guard4) {
    if (eta1 <= 0.253939833006323) {
      b_st.site = &eb_emlrtRSI;
      for (k = 0; k <= 14; k += 2) {
        dv1[0] = muDoubleScalarAbs(A[k]);
        dv1[1] = muDoubleScalarAbs(A[k + 1]);
        r = _mm_loadu_pd(&dv1[0]);
        _mm_storeu_pd(&scaledT[k],
                      _mm_mul_pd(_mm_set1_pd(0.12321872304378752), r));
      }
      for (i = 0; i < 4; i++) {
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          aBuffer[i + k] =
              ((scaledT[i] * scaledT[k] + scaledT[i + 4] * scaledT[k + 1]) +
               scaledT[i + 8] * scaledT[k + 2]) +
              scaledT[i + 12] * scaledT[k + 3];
        }
      }
      for (i = 0; i < 4; i++) {
        a = scaledT[i];
        y = scaledT[i + 4];
        d = scaledT[i + 8];
        d1 = scaledT[i + 12];
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          cBuffer[i + k] =
              ((a * aBuffer[k] + y * aBuffer[k + 1]) + d * aBuffer[k + 2]) +
              d1 * aBuffer[k + 3];
        }
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          scaledT[i + k] =
              ((aBuffer[i] * aBuffer[k] + aBuffer[i + 4] * aBuffer[k + 1]) +
               aBuffer[i + 8] * aBuffer[k + 2]) +
              aBuffer[i + 12] * aBuffer[k + 3];
        }
      }
      for (i = 0; i < 4; i++) {
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          b_scaledT[i + k] =
              ((scaledT[i] * scaledT[k] + scaledT[i + 4] * scaledT[k + 1]) +
               scaledT[i + 8] * scaledT[k + 2]) +
              scaledT[i + 12] * scaledT[k + 3];
        }
      }
      for (i = 0; i < 4; i++) {
        a = cBuffer[i];
        y = cBuffer[i + 4];
        d = cBuffer[i + 8];
        d1 = cBuffer[i + 12];
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          b_cBuffer[i + k] = ((a * b_scaledT[k] + y * b_scaledT[k + 1]) +
                              d * b_scaledT[k + 2]) +
                             d1 * b_scaledT[k + 3];
        }
      }
      c_st.site = &mb_emlrtRSI;
      a = b_log2(&c_st, 2.0 * (b_norm(b_cBuffer) / b_norm(A)) /
                            2.2204460492503131E-16) /
          10.0;
      if (muDoubleScalarMax(muDoubleScalarCeil(a), 0.0) == 0.0) {
        m = 5;
      } else {
        guard3 = true;
      }
    } else {
      guard3 = true;
    }
  }
  if (guard3) {
    b_st.site = &fb_emlrtRSI;
    for (i = 0; i < 4; i++) {
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        b_scaledT[i + k] =
            ((A4[i] * A4[k] + A4[i + 4] * A4[k + 1]) + A4[i + 8] * A4[k + 2]) +
            A4[i + 12] * A4[k + 3];
      }
    }
    eta1 = b_norm(b_scaledT);
    c_st.site = &j_emlrtRSI;
    if (eta1 < 0.0) {
      emlrtErrorWithMessageIdR2018a(&c_st, &e_emlrtRTEI,
                                    "Coder:toolbox:power_domainError",
                                    "Coder:toolbox:power_domainError", 0);
    }
    d8 = muDoubleScalarPower(eta1, 0.125);
    d6 = muDoubleScalarMax(d6, d8);
    if (d6 <= 0.95041789961629319) {
      b_st.site = &gb_emlrtRSI;
      for (k = 0; k <= 14; k += 2) {
        dv3[0] = muDoubleScalarAbs(A[k]);
        dv3[1] = muDoubleScalarAbs(A[k + 1]);
        r = _mm_loadu_pd(&dv3[0]);
        r = _mm_mul_pd(_mm_set1_pd(0.090475336558796943), r);
        _mm_storeu_pd(&scaledT[k], r);
        _mm_storeu_pd(&cBuffer[k], r);
      }
      for (i = 0; i < 4; i++) {
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          aBuffer[i + k] =
              ((scaledT[i] * scaledT[k] + scaledT[i + 4] * scaledT[k + 1]) +
               scaledT[i + 8] * scaledT[k + 2]) +
              scaledT[i + 12] * scaledT[k + 3];
        }
      }
      for (i = 0; i < 4; i++) {
        a = cBuffer[i];
        y = cBuffer[i + 4];
        d = cBuffer[i + 8];
        d1 = cBuffer[i + 12];
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          d2 = aBuffer[k];
          d3 = aBuffer[k + 1];
          d4 = aBuffer[k + 2];
          d5 = aBuffer[k + 3];
          cBuffer_tmp = i + k;
          b_cBuffer[cBuffer_tmp] = ((a * d2 + y * d3) + d * d4) + d1 * d5;
          scaledT[cBuffer_tmp] =
              ((aBuffer[i] * d2 + aBuffer[i + 4] * d3) + aBuffer[i + 8] * d4) +
              aBuffer[i + 12] * d5;
        }
      }
      for (i = 0; i < 4; i++) {
        a = b_cBuffer[i];
        y = b_cBuffer[i + 4];
        d = b_cBuffer[i + 8];
        d1 = b_cBuffer[i + 12];
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          d2 = scaledT[k];
          d3 = scaledT[k + 1];
          d4 = scaledT[k + 2];
          d5 = scaledT[k + 3];
          k += i;
          b_scaledT[k] =
              ((scaledT[i] * d2 + scaledT[i + 4] * d3) + scaledT[i + 8] * d4) +
              scaledT[i + 12] * d5;
          cBuffer[k] = ((a * d2 + y * d3) + d * d4) + d1 * d5;
        }
      }
      for (i = 0; i < 4; i++) {
        a = cBuffer[i];
        y = cBuffer[i + 4];
        d = cBuffer[i + 8];
        d1 = cBuffer[i + 12];
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          b_cBuffer[i + k] = ((a * b_scaledT[k] + y * b_scaledT[k + 1]) +
                              d * b_scaledT[k + 2]) +
                             d1 * b_scaledT[k + 3];
        }
      }
      c_st.site = &mb_emlrtRSI;
      a = b_log2(&c_st, 2.0 * (b_norm(b_cBuffer) / b_norm(A)) /
                            2.2204460492503131E-16) /
          14.0;
      if (muDoubleScalarMax(muDoubleScalarCeil(a), 0.0) == 0.0) {
        m = 7;
      } else {
        guard2 = true;
      }
    } else {
      guard2 = true;
    }
  }
  if (guard2) {
    if (d6 <= 2.097847961257068) {
      b_st.site = &hb_emlrtRSI;
      for (k = 0; k <= 14; k += 2) {
        dv2[0] = muDoubleScalarAbs(A[k]);
        dv2[1] = muDoubleScalarAbs(A[k + 1]);
        r = _mm_loadu_pd(&dv2[0]);
        _mm_storeu_pd(&scaledT[k],
                      _mm_mul_pd(_mm_set1_pd(0.071467735648795785), r));
      }
      for (i = 0; i < 4; i++) {
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          aBuffer[i + k] =
              ((scaledT[i] * scaledT[k] + scaledT[i + 4] * scaledT[k + 1]) +
               scaledT[i + 8] * scaledT[k + 2]) +
              scaledT[i + 12] * scaledT[k + 3];
        }
      }
      for (i = 0; i < 4; i++) {
        a = scaledT[i];
        y = scaledT[i + 4];
        d = scaledT[i + 8];
        d1 = scaledT[i + 12];
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          cBuffer[i + k] =
              ((a * aBuffer[k] + y * aBuffer[k + 1]) + d * aBuffer[k + 2]) +
              d1 * aBuffer[k + 3];
        }
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          scaledT[i + k] =
              ((aBuffer[i] * aBuffer[k] + aBuffer[i + 4] * aBuffer[k + 1]) +
               aBuffer[i + 8] * aBuffer[k + 2]) +
              aBuffer[i + 12] * aBuffer[k + 3];
        }
      }
      for (i = 0; i < 4; i++) {
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          aBuffer[i + k] =
              ((scaledT[i] * scaledT[k] + scaledT[i + 4] * scaledT[k + 1]) +
               scaledT[i + 8] * scaledT[k + 2]) +
              scaledT[i + 12] * scaledT[k + 3];
        }
      }
      for (i = 0; i < 4; i++) {
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          b_aBuffer[i + k] =
              ((aBuffer[i] * aBuffer[k] + aBuffer[i + 4] * aBuffer[k + 1]) +
               aBuffer[i + 8] * aBuffer[k + 2]) +
              aBuffer[i + 12] * aBuffer[k + 3];
        }
      }
      for (i = 0; i < 4; i++) {
        a = cBuffer[i];
        y = cBuffer[i + 4];
        d = cBuffer[i + 8];
        d1 = cBuffer[i + 12];
        for (i1 = 0; i1 < 4; i1++) {
          k = i1 << 2;
          b_cBuffer[i + k] = ((a * b_aBuffer[k] + y * b_aBuffer[k + 1]) +
                              d * b_aBuffer[k + 2]) +
                             d1 * b_aBuffer[k + 3];
        }
      }
      c_st.site = &mb_emlrtRSI;
      a = b_log2(&c_st, 2.0 * (b_norm(b_cBuffer) / b_norm(A)) /
                            2.2204460492503131E-16) /
          18.0;
      if (muDoubleScalarMax(muDoubleScalarCeil(a), 0.0) == 0.0) {
        m = 9;
      } else {
        guard1 = true;
      }
    } else {
      guard1 = true;
    }
  }
  if (guard1) {
    boolean_T exitg1;
    b_st.site = &ib_emlrtRSI;
    for (i = 0; i < 4; i++) {
      a = A4[i];
      y = A4[i + 4];
      d = A4[i + 8];
      d1 = A4[i + 12];
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        b_scaledT[i + k] =
            ((a * A6[k] + y * A6[k + 1]) + d * A6[k + 2]) + d1 * A6[k + 3];
      }
    }
    eta1 = b_norm(b_scaledT);
    c_st.site = &j_emlrtRSI;
    if (eta1 < 0.0) {
      emlrtErrorWithMessageIdR2018a(&c_st, &e_emlrtRTEI,
                                    "Coder:toolbox:power_domainError",
                                    "Coder:toolbox:power_domainError", 0);
    }
    b_st.site = &jb_emlrtRSI;
    a = b_log2(&b_st,
               muDoubleScalarMin(
                   d6, muDoubleScalarMax(d8, muDoubleScalarPower(eta1, 0.1))) /
                   5.3719203511481517);
    *s = muDoubleScalarMax(muDoubleScalarCeil(a), 0.0);
    b_st.site = &kb_emlrtRSI;
    a = muDoubleScalarPower(2.0, *s);
    b_st.site = &kb_emlrtRSI;
    for (i = 0; i <= 14; i += 2) {
      _mm_storeu_pd(&T[i], _mm_div_pd(_mm_loadu_pd(&A[i]), _mm_set1_pd(a)));
    }
    for (k = 0; k <= 14; k += 2) {
      dv4[0] = muDoubleScalarAbs(T[k]);
      dv4[1] = muDoubleScalarAbs(T[k + 1]);
      r = _mm_loadu_pd(&dv4[0]);
      _mm_storeu_pd(&scaledT[k],
                    _mm_mul_pd(_mm_set1_pd(0.05031554467093536), r));
    }
    for (i = 0; i < 4; i++) {
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        aBuffer[i + k] =
            ((scaledT[i] * scaledT[k] + scaledT[i + 4] * scaledT[k + 1]) +
             scaledT[i + 8] * scaledT[k + 2]) +
            scaledT[i + 12] * scaledT[k + 3];
      }
    }
    for (i = 0; i < 4; i++) {
      a = scaledT[i];
      y = scaledT[i + 4];
      d = scaledT[i + 8];
      d1 = scaledT[i + 12];
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        b_scaledT[i + k] =
            ((a * aBuffer[k] + y * aBuffer[k + 1]) + d * aBuffer[k + 2]) +
            d1 * aBuffer[k + 3];
      }
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        scaledT[i + k] =
            ((aBuffer[i] * aBuffer[k] + aBuffer[i + 4] * aBuffer[k + 1]) +
             aBuffer[i + 8] * aBuffer[k + 2]) +
            aBuffer[i + 12] * aBuffer[k + 3];
      }
    }
    for (i = 0; i < 4; i++) {
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        aBuffer[i + k] =
            ((scaledT[i] * scaledT[k] + scaledT[i + 4] * scaledT[k + 1]) +
             scaledT[i + 8] * scaledT[k + 2]) +
            scaledT[i + 12] * scaledT[k + 3];
      }
    }
    for (i = 0; i < 4; i++) {
      a = b_scaledT[i];
      y = b_scaledT[i + 4];
      d = b_scaledT[i + 8];
      d1 = b_scaledT[i + 12];
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        d2 = aBuffer[k];
        d3 = aBuffer[k + 1];
        d4 = aBuffer[k + 2];
        d5 = aBuffer[k + 3];
        k += i;
        b_aBuffer[k] =
            ((aBuffer[i] * d2 + aBuffer[i + 4] * d3) + aBuffer[i + 8] * d4) +
            aBuffer[i + 12] * d5;
        b_cBuffer[k] = ((a * d2 + y * d3) + d * d4) + d1 * d5;
      }
    }
    for (i = 0; i < 4; i++) {
      a = b_cBuffer[i];
      y = b_cBuffer[i + 4];
      d = b_cBuffer[i + 8];
      d1 = b_cBuffer[i + 12];
      for (i1 = 0; i1 < 4; i1++) {
        k = i1 << 2;
        cBuffer[i + k] =
            ((a * b_aBuffer[k] + y * b_aBuffer[k + 1]) + d * b_aBuffer[k + 2]) +
            d1 * b_aBuffer[k + 3];
      }
    }
    a = 0.0;
    k = 0;
    exitg1 = false;
    while ((!exitg1) && (k < 4)) {
      cBuffer_tmp = k << 2;
      eta1 = ((muDoubleScalarAbs(cBuffer[cBuffer_tmp]) +
               muDoubleScalarAbs(cBuffer[cBuffer_tmp + 1])) +
              muDoubleScalarAbs(cBuffer[cBuffer_tmp + 2])) +
             muDoubleScalarAbs(cBuffer[cBuffer_tmp + 3]);
      if (muDoubleScalarIsNaN(eta1)) {
        a = rtNaN;
        exitg1 = true;
      } else {
        if (eta1 > a) {
          a = eta1;
        }
        k++;
      }
    }
    y = 0.0;
    k = 0;
    exitg1 = false;
    while ((!exitg1) && (k < 4)) {
      cBuffer_tmp = k << 2;
      eta1 = ((muDoubleScalarAbs(T[cBuffer_tmp]) +
               muDoubleScalarAbs(T[cBuffer_tmp + 1])) +
              muDoubleScalarAbs(T[cBuffer_tmp + 2])) +
             muDoubleScalarAbs(T[cBuffer_tmp + 3]);
      if (muDoubleScalarIsNaN(eta1)) {
        y = rtNaN;
        exitg1 = true;
      } else {
        if (eta1 > y) {
          y = eta1;
        }
        k++;
      }
    }
    c_st.site = &mb_emlrtRSI;
    a = b_log2(&c_st, 2.0 * (a / y) / 2.2204460492503131E-16) / 26.0;
    *s += muDoubleScalarMax(muDoubleScalarCeil(a), 0.0);
    if (muDoubleScalarIsInf(*s)) {
      a = b_norm(A) / 5.3719203511481517;
      if ((!muDoubleScalarIsInf(a)) && (!muDoubleScalarIsNaN(a))) {
        a = frexp(a, &eint);
      } else {
        eint = 0;
      }
      *s = eint;
      if (a == 0.5) {
        *s = (real_T)eint - 1.0;
      }
    }
    m = 13;
  }
  return m;
}

static void padeApproximation(const emlrtStack *sp, const real_T A[16],
                              const real_T A2[16], const real_T A4[16],
                              const real_T A6[16], int32_T m, real_T F[16])
{
  __m128d r;
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
  real_T V[16];
  real_T b_A6[16];
  real_T d;
  real_T s;
  int32_T b_i;
  int32_T b_tmp;
  int32_T i;
  int32_T info;
  int32_T j;
  int32_T jA;
  int32_T jBcol;
  int32_T jp1j;
  int32_T k;
  int8_T ipiv[4];
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
  if (m == 3) {
    memcpy(&F[0], &A2[0], 16U * sizeof(real_T));
    F[0] += 60.0;
    F[5] += 60.0;
    F[10] += 60.0;
    F[15] += 60.0;
    for (i = 0; i < 4; i++) {
      real_T b_d;
      real_T d1;
      d = A[i];
      s = A[i + 4];
      b_d = A[i + 8];
      d1 = A[i + 12];
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        jBcol = b_tmp << 2;
        b_A6[i + jBcol] =
            ((d * F[jBcol] + s * F[jBcol + 1]) + b_d * F[jBcol + 2]) +
            d1 * F[jBcol + 3];
      }
    }
    for (i = 0; i <= 14; i += 2) {
      r = _mm_loadu_pd(&b_A6[i]);
      _mm_storeu_pd(&F[i], r);
      _mm_storeu_pd(&V[i], _mm_mul_pd(_mm_set1_pd(12.0), _mm_loadu_pd(&A2[i])));
    }
    d = 120.0;
  } else if (m == 5) {
    for (i = 0; i <= 14; i += 2) {
      _mm_storeu_pd(&F[i], _mm_add_pd(_mm_loadu_pd(&A4[i]),
                                      _mm_mul_pd(_mm_set1_pd(420.0),
                                                 _mm_loadu_pd(&A2[i]))));
    }
    F[0] += 15120.0;
    F[5] += 15120.0;
    F[10] += 15120.0;
    F[15] += 15120.0;
    for (i = 0; i < 4; i++) {
      real_T b_d;
      real_T d1;
      d = A[i];
      s = A[i + 4];
      b_d = A[i + 8];
      d1 = A[i + 12];
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        jBcol = b_tmp << 2;
        b_A6[i + jBcol] =
            ((d * F[jBcol] + s * F[jBcol + 1]) + b_d * F[jBcol + 2]) +
            d1 * F[jBcol + 3];
      }
    }
    for (i = 0; i <= 14; i += 2) {
      r = _mm_loadu_pd(&b_A6[i]);
      _mm_storeu_pd(&F[i], r);
      _mm_storeu_pd(
          &V[i],
          _mm_add_pd(_mm_mul_pd(_mm_set1_pd(30.0), _mm_loadu_pd(&A4[i])),
                     _mm_mul_pd(_mm_set1_pd(3360.0), _mm_loadu_pd(&A2[i]))));
    }
    d = 30240.0;
  } else if (m == 7) {
    for (i = 0; i <= 14; i += 2) {
      _mm_storeu_pd(
          &F[i],
          _mm_add_pd(
              _mm_add_pd(_mm_loadu_pd(&A6[i]),
                         _mm_mul_pd(_mm_set1_pd(1512.0), _mm_loadu_pd(&A4[i]))),
              _mm_mul_pd(_mm_set1_pd(277200.0), _mm_loadu_pd(&A2[i]))));
    }
    F[0] += 8.64864E+6;
    F[5] += 8.64864E+6;
    F[10] += 8.64864E+6;
    F[15] += 8.64864E+6;
    for (i = 0; i < 4; i++) {
      real_T b_d;
      real_T d1;
      d = A[i];
      s = A[i + 4];
      b_d = A[i + 8];
      d1 = A[i + 12];
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        jBcol = b_tmp << 2;
        b_A6[i + jBcol] =
            ((d * F[jBcol] + s * F[jBcol + 1]) + b_d * F[jBcol + 2]) +
            d1 * F[jBcol + 3];
      }
    }
    for (i = 0; i <= 14; i += 2) {
      r = _mm_loadu_pd(&b_A6[i]);
      _mm_storeu_pd(&F[i], r);
      _mm_storeu_pd(
          &V[i],
          _mm_add_pd(
              _mm_add_pd(
                  _mm_mul_pd(_mm_set1_pd(56.0), _mm_loadu_pd(&A6[i])),
                  _mm_mul_pd(_mm_set1_pd(25200.0), _mm_loadu_pd(&A4[i]))),
              _mm_mul_pd(_mm_set1_pd(1.99584E+6), _mm_loadu_pd(&A2[i]))));
    }
    d = 1.729728E+7;
  } else if (m == 9) {
    real_T b_d;
    real_T d1;
    for (i = 0; i < 4; i++) {
      d = A6[i];
      s = A6[i + 4];
      b_d = A6[i + 8];
      d1 = A6[i + 12];
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        jBcol = b_tmp << 2;
        V[i + jBcol] =
            ((d * A2[jBcol] + s * A2[jBcol + 1]) + b_d * A2[jBcol + 2]) +
            d1 * A2[jBcol + 3];
      }
    }
    for (i = 0; i <= 14; i += 2) {
      r = _mm_loadu_pd(&V[i]);
      _mm_storeu_pd(
          &F[i],
          _mm_add_pd(
              _mm_add_pd(
                  _mm_add_pd(
                      r, _mm_mul_pd(_mm_set1_pd(3960.0), _mm_loadu_pd(&A6[i]))),
                  _mm_mul_pd(_mm_set1_pd(2.16216E+6), _mm_loadu_pd(&A4[i]))),
              _mm_mul_pd(_mm_set1_pd(3.027024E+8), _mm_loadu_pd(&A2[i]))));
    }
    F[0] += 8.8216128E+9;
    F[5] += 8.8216128E+9;
    F[10] += 8.8216128E+9;
    F[15] += 8.8216128E+9;
    for (i = 0; i < 4; i++) {
      d = A[i];
      s = A[i + 4];
      b_d = A[i + 8];
      d1 = A[i + 12];
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        jBcol = b_tmp << 2;
        b_A6[i + jBcol] =
            ((d * F[jBcol] + s * F[jBcol + 1]) + b_d * F[jBcol + 2]) +
            d1 * F[jBcol + 3];
      }
    }
    for (i = 0; i <= 14; i += 2) {
      r = _mm_loadu_pd(&b_A6[i]);
      _mm_storeu_pd(&F[i], r);
      r = _mm_loadu_pd(&V[i]);
      _mm_storeu_pd(
          &V[i],
          _mm_add_pd(
              _mm_add_pd(
                  _mm_add_pd(
                      _mm_mul_pd(_mm_set1_pd(90.0), r),
                      _mm_mul_pd(_mm_set1_pd(110880.0), _mm_loadu_pd(&A6[i]))),
                  _mm_mul_pd(_mm_set1_pd(3.027024E+7), _mm_loadu_pd(&A4[i]))),
              _mm_mul_pd(_mm_set1_pd(2.0756736E+9), _mm_loadu_pd(&A2[i]))));
    }
    d = 1.76432256E+10;
  } else {
    real_T b_d;
    real_T d1;
    for (i = 0; i <= 14; i += 2) {
      _mm_storeu_pd(
          &F[i],
          _mm_add_pd(_mm_add_pd(_mm_mul_pd(_mm_set1_pd(3.352212864E+10),
                                           _mm_loadu_pd(&A6[i])),
                                _mm_mul_pd(_mm_set1_pd(1.05594705216E+13),
                                           _mm_loadu_pd(&A4[i]))),
                     _mm_mul_pd(_mm_set1_pd(1.1873537964288E+15),
                                _mm_loadu_pd(&A2[i]))));
      _mm_storeu_pd(&b_A6[i],
                    _mm_add_pd(_mm_add_pd(_mm_loadu_pd(&A6[i]),
                                          _mm_mul_pd(_mm_set1_pd(16380.0),
                                                     _mm_loadu_pd(&A4[i]))),
                               _mm_mul_pd(_mm_set1_pd(4.08408E+7),
                                          _mm_loadu_pd(&A2[i]))));
    }
    F[0] += 3.238237626624E+16;
    F[5] += 3.238237626624E+16;
    F[10] += 3.238237626624E+16;
    F[15] += 3.238237626624E+16;
    for (i = 0; i < 4; i++) {
      d = A6[i];
      s = A6[i + 4];
      b_d = A6[i + 8];
      d1 = A6[i + 12];
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        jBcol = b_tmp << 2;
        jA = i + jBcol;
        V[jA] =
            (((d * b_A6[jBcol] + s * b_A6[jBcol + 1]) + b_d * b_A6[jBcol + 2]) +
             d1 * b_A6[jBcol + 3]) +
            F[jA];
      }
    }
    for (i = 0; i < 4; i++) {
      d = A[i];
      s = A[i + 4];
      b_d = A[i + 8];
      d1 = A[i + 12];
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        jBcol = b_tmp << 2;
        F[i + jBcol] =
            ((d * V[jBcol] + s * V[jBcol + 1]) + b_d * V[jBcol + 2]) +
            d1 * V[jBcol + 3];
      }
    }
    for (i = 0; i <= 14; i += 2) {
      _mm_storeu_pd(
          &b_A6[i],
          _mm_add_pd(
              _mm_add_pd(
                  _mm_mul_pd(_mm_set1_pd(182.0), _mm_loadu_pd(&A6[i])),
                  _mm_mul_pd(_mm_set1_pd(960960.0), _mm_loadu_pd(&A4[i]))),
              _mm_mul_pd(_mm_set1_pd(1.32324192E+9), _mm_loadu_pd(&A2[i]))));
    }
    for (i = 0; i < 4; i++) {
      for (b_tmp = 0; b_tmp < 4; b_tmp++) {
        jBcol = b_tmp << 2;
        jA = i + jBcol;
        V[jA] = (((((A6[i] * b_A6[jBcol] + A6[i + 4] * b_A6[jBcol + 1]) +
                    A6[i + 8] * b_A6[jBcol + 2]) +
                   A6[i + 12] * b_A6[jBcol + 3]) +
                  6.704425728E+11 * A6[jA]) +
                 1.29060195264E+14 * A4[jA]) +
                7.7717703038976E+15 * A2[jA];
      }
    }
    d = 6.476475253248E+16;
  }
  V[0] += d;
  V[5] += d;
  V[10] += d;
  V[15] += d;
  for (k = 0; k <= 14; k += 2) {
    __m128d r1;
    r = _mm_loadu_pd(&V[k]);
    r1 = _mm_loadu_pd(&F[k]);
    _mm_storeu_pd(&V[k], _mm_sub_pd(r, r1));
    _mm_storeu_pd(&F[k], _mm_mul_pd(_mm_set1_pd(2.0), r1));
  }
  st.site = &nb_emlrtRSI;
  b_st.site = &ob_emlrtRSI;
  c_st.site = &pb_emlrtRSI;
  d_st.site = &rb_emlrtRSI;
  e_st.site = &sb_emlrtRSI;
  f_st.site = &tb_emlrtRSI;
  ipiv[0] = 1;
  ipiv[1] = 2;
  ipiv[2] = 3;
  ipiv[3] = 4;
  info = 0;
  for (j = 0; j < 3; j++) {
    b_tmp = j * 5;
    jp1j = b_tmp + 2;
    jA = 4 - j;
    jBcol = 0;
    d = muDoubleScalarAbs(V[b_tmp]);
    for (k = 2; k <= jA; k++) {
      s = muDoubleScalarAbs(V[(b_tmp + k) - 1]);
      if (s > d) {
        jBcol = k - 1;
        d = s;
      }
    }
    if (V[b_tmp + jBcol] != 0.0) {
      if (jBcol != 0) {
        jBcol += j;
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
      i = (b_tmp - j) + 4;
      g_st.site = &ub_emlrtRSI;
      for (b_i = jp1j; b_i <= i; b_i++) {
        V[b_i - 1] /= V[b_tmp];
      }
    } else {
      info = j + 1;
    }
    i = 2 - j;
    g_st.site = &vb_emlrtRSI;
    h_st.site = &wb_emlrtRSI;
    i_st.site = &xb_emlrtRSI;
    j_st.site = &yb_emlrtRSI;
    jA = b_tmp + 6;
    for (jp1j = 0; jp1j <= i; jp1j++) {
      d = V[(b_tmp + (jp1j << 2)) + 4];
      if (d != 0.0) {
        jBcol = (jA - j) + 2;
        k_st.site = &ac_emlrtRSI;
        if ((jA <= jBcol) && (jBcol > 2147483646)) {
          l_st.site = &x_emlrtRSI;
          check_forloop_overflow_error(&l_st);
        }
        for (b_i = jA; b_i <= jBcol; b_i++) {
          V[b_i - 1] += V[((b_tmp + b_i) - jA) + 1] * -d;
        }
      }
      jA += 4;
    }
  }
  if ((info == 0) && (!(V[15] != 0.0))) {
    info = 4;
  }
  for (b_i = 0; b_i < 3; b_i++) {
    int8_T i1;
    i1 = ipiv[b_i];
    if (i1 != b_i + 1) {
      d = F[b_i];
      F[b_i] = F[i1 - 1];
      F[i1 - 1] = d;
      d = F[b_i + 4];
      F[b_i + 4] = F[i1 + 3];
      F[i1 + 3] = d;
      d = F[b_i + 8];
      F[b_i + 8] = F[i1 + 7];
      F[i1 + 7] = d;
      d = F[b_i + 12];
      F[b_i + 12] = F[i1 + 11];
      F[i1 + 11] = d;
    }
  }
  for (j = 0; j < 4; j++) {
    jBcol = j << 2;
    for (k = 0; k < 4; k++) {
      jA = k << 2;
      i = k + jBcol;
      if (F[i] != 0.0) {
        b_tmp = k + 2;
        for (b_i = b_tmp; b_i < 5; b_i++) {
          jp1j = (b_i + jBcol) - 1;
          F[jp1j] -= F[i] * V[(b_i + jA) - 1];
        }
      }
    }
  }
  for (j = 0; j < 4; j++) {
    jBcol = j << 2;
    for (k = 3; k >= 0; k--) {
      jA = k << 2;
      i = k + jBcol;
      d = F[i];
      if (d != 0.0) {
        F[i] = d / V[k + jA];
        for (b_i = 0; b_i < k; b_i++) {
          jp1j = b_i + jBcol;
          F[jp1j] -= F[i] * V[b_i + jA];
        }
      }
    }
  }
  if (info > 0) {
    c_st.site = &qb_emlrtRSI;
    d_st.site = &bc_emlrtRSI;
    warning(&d_st);
  }
  F[0]++;
  F[5]++;
  F[10]++;
  F[15]++;
}

static void recomputeBlockDiag(const real_T A[16], real_T F[16],
                               const int32_T blockFormat[3])
{
  real_T delta;
  real_T expa;
  real_T expa22;
  real_T sinchdelta;
  if (blockFormat[0] != 0) {
    if (blockFormat[0] == 1) {
      sinchdelta = muDoubleScalarExp(A[0]);
      expa22 = muDoubleScalarExp(A[5]);
      expa = (A[0] + A[5]) / 2.0;
      if (muDoubleScalarMax(expa, muDoubleScalarAbs(A[0] - A[5]) / 2.0) <
          709.782712893384) {
        delta = (A[5] - A[0]) / 2.0;
        if (delta == 0.0) {
          delta = 1.0;
        } else {
          delta = muDoubleScalarSinh(delta) / delta;
        }
        delta *= A[4] * muDoubleScalarExp(expa);
      } else {
        delta = A[4] * (expa22 - sinchdelta) / (A[5] - A[0]);
      }
      F[0] = sinchdelta;
      F[4] = delta;
      F[5] = expa22;
    } else {
      delta = muDoubleScalarSqrt(muDoubleScalarAbs(A[1] * A[4]));
      expa = muDoubleScalarExp(A[0]);
      if (delta == 0.0) {
        sinchdelta = 1.0;
      } else {
        sinchdelta = muDoubleScalarSin(delta) / delta;
      }
      F[0] = expa * muDoubleScalarCos(delta);
      F[1] = expa * A[1] * sinchdelta;
      F[4] = expa * A[4] * sinchdelta;
      F[5] = F[0];
    }
  }
  if (blockFormat[1] != 0) {
    if (blockFormat[1] == 1) {
      sinchdelta = muDoubleScalarExp(A[5]);
      expa22 = muDoubleScalarExp(A[10]);
      expa = (A[5] + A[10]) / 2.0;
      if (muDoubleScalarMax(expa, muDoubleScalarAbs(A[5] - A[10]) / 2.0) <
          709.782712893384) {
        delta = (A[10] - A[5]) / 2.0;
        if (delta == 0.0) {
          delta = 1.0;
        } else {
          delta = muDoubleScalarSinh(delta) / delta;
        }
        delta *= A[9] * muDoubleScalarExp(expa);
      } else {
        delta = A[9] * (expa22 - sinchdelta) / (A[10] - A[5]);
      }
      F[5] = sinchdelta;
      F[9] = delta;
      F[10] = expa22;
    } else {
      delta = muDoubleScalarSqrt(muDoubleScalarAbs(A[6] * A[9]));
      expa = muDoubleScalarExp(A[5]);
      if (delta == 0.0) {
        sinchdelta = 1.0;
      } else {
        sinchdelta = muDoubleScalarSin(delta) / delta;
      }
      F[5] = expa * muDoubleScalarCos(delta);
      F[6] = expa * A[6] * sinchdelta;
      F[9] = expa * A[9] * sinchdelta;
      F[10] = F[5];
    }
  }
  if (blockFormat[2] != 0) {
    if (blockFormat[2] == 1) {
      sinchdelta = muDoubleScalarExp(A[10]);
      expa22 = muDoubleScalarExp(A[15]);
      expa = (A[10] + A[15]) / 2.0;
      if (muDoubleScalarMax(expa, muDoubleScalarAbs(A[10] - A[15]) / 2.0) <
          709.782712893384) {
        delta = (A[15] - A[10]) / 2.0;
        if (delta == 0.0) {
          delta = 1.0;
        } else {
          delta = muDoubleScalarSinh(delta) / delta;
        }
        delta *= A[14] * muDoubleScalarExp(expa);
      } else {
        delta = A[14] * (expa22 - sinchdelta) / (A[15] - A[10]);
      }
      F[10] = sinchdelta;
      F[14] = delta;
      F[15] = expa22;
    } else {
      delta = muDoubleScalarSqrt(muDoubleScalarAbs(A[11] * A[14]));
      expa = muDoubleScalarExp(A[10]);
      if (delta == 0.0) {
        sinchdelta = 1.0;
      } else {
        sinchdelta = muDoubleScalarSin(delta) / delta;
      }
      F[10] = expa * muDoubleScalarCos(delta);
      F[11] = expa * A[11] * sinchdelta;
      F[14] = expa * A[14] * sinchdelta;
      F[15] = F[10];
    }
  }
  if (blockFormat[2] == 0) {
    F[15] = muDoubleScalarExp(A[15]);
  }
}

void expm(const emlrtStack *sp, real_T A[16], real_T F[16])
{
  static const char_T fname[13] = {'L', 'A', 'P', 'A', 'C', 'K', 'E',
                                   '_', 'd', 's', 'y', 'e', 'v'};
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack st;
  real_T A2[16];
  real_T A4[16];
  real_T A6[16];
  real_T W[4];
  real_T s;
  int32_T i;
  int32_T i1;
  int32_T i2;
  int32_T k;
  boolean_T recomputeDiags;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  recomputeDiags = true;
  for (k = 0; k < 16; k++) {
    if (recomputeDiags) {
      s = A[k];
      if (muDoubleScalarIsInf(s) || muDoubleScalarIsNaN(s)) {
        recomputeDiags = false;
      }
    } else {
      recomputeDiags = false;
    }
  }
  if (!recomputeDiags) {
    for (i = 0; i < 16; i++) {
      F[i] = rtNaN;
    }
  } else {
    int32_T b_i;
    int32_T exitg1;
    boolean_T exitg2;
    recomputeDiags = true;
    k = 0;
    exitg2 = false;
    while ((!exitg2) && (k < 4)) {
      b_i = 0;
      do {
        exitg1 = 0;
        if (b_i < 4) {
          if ((b_i != k) && (!(A[b_i + (k << 2)] == 0.0))) {
            recomputeDiags = false;
            exitg1 = 1;
          } else {
            b_i++;
          }
        } else {
          k++;
          exitg1 = 2;
        }
      } while (exitg1 == 0);
      if (exitg1 == 1) {
        exitg2 = true;
      }
    }
    if (recomputeDiags) {
      memset(&F[0], 0, 16U * sizeof(real_T));
      F[0] = muDoubleScalarExp(A[0]);
      F[5] = muDoubleScalarExp(A[5]);
      F[10] = muDoubleScalarExp(A[10]);
      F[15] = muDoubleScalarExp(A[15]);
    } else {
      recomputeDiags = true;
      k = 0;
      exitg2 = false;
      while ((!exitg2) && (k < 4)) {
        b_i = 0;
        do {
          exitg1 = 0;
          if (b_i <= k) {
            if (!(A[b_i + (k << 2)] == A[k + (b_i << 2)])) {
              recomputeDiags = false;
              exitg1 = 1;
            } else {
              b_i++;
            }
          } else {
            k++;
            exitg1 = 2;
          }
        } while (exitg1 == 0);
        if (exitg1 == 1) {
          exitg2 = true;
        }
      }
      if (recomputeDiags) {
        ptrdiff_t n_t;
        st.site = &m_emlrtRSI;
        memcpy(&A2[0], &A[0], 16U * sizeof(real_T));
        b_st.site = &v_emlrtRSI;
        n_t = (ptrdiff_t)4;
        n_t = LAPACKE_dsyev(102, 'V', 'L', n_t, &A2[0], n_t, &W[0]);
        c_st.site = &w_emlrtRSI;
        if ((int32_T)n_t < 0) {
          if ((int32_T)n_t == -1010) {
            emlrtErrorWithMessageIdR2018a(&c_st, &c_emlrtRTEI, "MATLAB:nomem",
                                          "MATLAB:nomem", 0);
          } else {
            emlrtErrorWithMessageIdR2018a(
                &c_st, &d_emlrtRTEI, "Coder:toolbox:LAPACKCallErrorInfo",
                "Coder:toolbox:LAPACKCallErrorInfo", 5, 4, 13, &fname[0], 12,
                (int32_T)n_t);
          }
        }
        for (k = 0; k < 4; k++) {
          __m128d r;
          __m128d r1;
          i = k << 2;
          r = _mm_loadu_pd(&A2[i]);
          r1 = _mm_set1_pd(muDoubleScalarExp(W[k]));
          _mm_storeu_pd(&F[i], _mm_mul_pd(r, r1));
          r = _mm_loadu_pd(&A2[i + 2]);
          _mm_storeu_pd(&F[i + 2], _mm_mul_pd(r, r1));
        }
        for (i = 0; i < 4; i++) {
          real_T d;
          real_T d1;
          real_T y;
          s = F[i];
          y = F[i + 4];
          d = F[i + 8];
          d1 = F[i + 12];
          for (i1 = 0; i1 < 4; i1++) {
            A4[i + (i1 << 2)] =
                ((s * A2[i1] + y * A2[i1 + 4]) + d * A2[i1 + 8]) +
                d1 * A2[i1 + 12];
          }
        }
        memcpy(&F[0], &A4[0], 16U * sizeof(real_T));
        for (i = 0; i < 4; i++) {
          b_i = i << 2;
          A4[b_i] = (F[b_i] + F[i]) / 2.0;
          A4[b_i + 1] = (F[b_i + 1] + F[i + 4]) / 2.0;
          A4[b_i + 2] = (F[b_i + 2] + F[i + 8]) / 2.0;
          A4[b_i + 3] = (F[b_i + 3] + F[i + 12]) / 2.0;
        }
        memcpy(&F[0], &A4[0], 16U * sizeof(real_T));
      } else {
        __m128d r;
        int32_T blockFormat[3];
        recomputeDiags = true;
        k = 3;
        while (recomputeDiags && (k <= 4)) {
          b_i = k;
          while (recomputeDiags && (b_i <= 4)) {
            recomputeDiags = (A[(b_i + ((k - 3) << 2)) - 1] == 0.0);
            b_i++;
          }
          k++;
        }
        if (recomputeDiags) {
          k = 0;
          exitg2 = false;
          while ((!exitg2) && (k < 3)) {
            i = k + (k << 2);
            s = A[i + 1];
            if (s != 0.0) {
              if ((k + 1 != 3) && (A[(k + ((k + 1) << 2)) + 2] != 0.0)) {
                recomputeDiags = false;
                exitg2 = true;
              } else {
                i1 = k + ((k + 1) << 2);
                if ((A[i] != A[i1 + 1]) ||
                    (muDoubleScalarSign(s) * muDoubleScalarSign(A[i1]) !=
                     -1.0)) {
                  recomputeDiags = false;
                  exitg2 = true;
                } else {
                  k++;
                }
              }
            } else {
              k++;
            }
          }
        }
        st.site = &n_emlrtRSI;
        b_i = getExpmParams(&st, A, A2, A4, A6, &s);
        if (s != 0.0) {
          real_T y;
          st.site = &o_emlrtRSI;
          b_st.site = &j_emlrtRSI;
          y = muDoubleScalarPower(2.0, s);
          for (i = 0; i <= 14; i += 2) {
            r = _mm_loadu_pd(&A[i]);
            _mm_storeu_pd(&A[i], _mm_div_pd(r, _mm_set1_pd(y)));
          }
          st.site = &p_emlrtRSI;
          b_st.site = &j_emlrtRSI;
          y = muDoubleScalarPower(2.0, 2.0 * s);
          for (i = 0; i <= 14; i += 2) {
            r = _mm_loadu_pd(&A2[i]);
            _mm_storeu_pd(&A2[i], _mm_div_pd(r, _mm_set1_pd(y)));
          }
          st.site = &q_emlrtRSI;
          b_st.site = &j_emlrtRSI;
          y = muDoubleScalarPower(2.0, 4.0 * s);
          for (i = 0; i <= 14; i += 2) {
            r = _mm_loadu_pd(&A4[i]);
            _mm_storeu_pd(&A4[i], _mm_div_pd(r, _mm_set1_pd(y)));
          }
          st.site = &r_emlrtRSI;
          b_st.site = &j_emlrtRSI;
          y = muDoubleScalarPower(2.0, 6.0 * s);
          for (i = 0; i <= 14; i += 2) {
            r = _mm_loadu_pd(&A6[i]);
            _mm_storeu_pd(&A6[i], _mm_div_pd(r, _mm_set1_pd(y)));
          }
        }
        if (recomputeDiags) {
          blockFormat[0] = 0;
          blockFormat[1] = 0;
          blockFormat[2] = 0;
          k = 0;
          while (k + 1 < 3) {
            if (A[(k + (k << 2)) + 1] != 0.0) {
              blockFormat[k] = 2;
              blockFormat[k + 1] = 0;
              k += 2;
            } else if (A[(k + ((k + 1) << 2)) + 2] == 0.0) {
              blockFormat[k] = 1;
              k++;
            } else {
              blockFormat[k] = 0;
              k++;
            }
          }
          if (A[11] != 0.0) {
            blockFormat[2] = 2;
          } else if ((blockFormat[1] == 0) || (blockFormat[1] == 1)) {
            blockFormat[2] = 1;
          }
        }
        st.site = &s_emlrtRSI;
        padeApproximation(&st, A, A2, A4, A6, b_i, F);
        if (recomputeDiags) {
          st.site = &t_emlrtRSI;
          recomputeBlockDiag(A, F, blockFormat);
        }
        i = (int32_T)s;
        emlrtForLoopVectorCheckR2021a(1.0, 1.0, s, mxDOUBLE_CLASS, (int32_T)s,
                                      &b_emlrtRTEI, (emlrtConstCTX)sp);
        for (k = 0; k < i; k++) {
          for (i1 = 0; i1 < 4; i1++) {
            for (i2 = 0; i2 < 4; i2++) {
              b_i = i2 << 2;
              A4[i1 + b_i] = ((F[i1] * F[b_i] + F[i1 + 4] * F[b_i + 1]) +
                              F[i1 + 8] * F[b_i + 2]) +
                             F[i1 + 12] * F[b_i + 3];
            }
          }
          memcpy(&F[0], &A4[0], 16U * sizeof(real_T));
          if (recomputeDiags) {
            for (i1 = 0; i1 <= 14; i1 += 2) {
              r = _mm_loadu_pd(&A[i1]);
              _mm_storeu_pd(&A[i1], _mm_mul_pd(_mm_set1_pd(2.0), r));
            }
            st.site = &u_emlrtRSI;
            recomputeBlockDiag(A, F, blockFormat);
          }
        }
      }
    }
  }
}

/* End of code generation (expm.c) */
