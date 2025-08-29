/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * quat2rotm.c
 *
 * Code generation for function 'quat2rotm'
 *
 */

/* Include files */
#include "quat2rotm.h"
#include "rt_nonfinite.h"
#include "sumMatrixIncludeNaN.h"
#include "mwmathutil.h"
#include <emmintrin.h>
#include <string.h>

/* Variable Definitions */
static emlrtRSInfo d_emlrtRSI =
    {
        37,          /* lineNo */
        "quat2rotm", /* fcnName */
        "/usr/local/MATLAB/R2024a/toolbox/shared/robotics/robotutils/"
        "quat2rotm.m" /* pathName */
};

static emlrtRSInfo e_emlrtRSI = {
    22,          /* lineNo */
    "quat2rotm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/shared/robotics/robotutilsint/+robotics/"
    "+internal/quat2rotm.m" /* pathName */
};

static emlrtRSInfo f_emlrtRSI = {
    33,          /* lineNo */
    "quat2rotm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/shared/robotics/robotutilsint/+robotics/"
    "+internal/quat2rotm.m" /* pathName */
};

static emlrtRSInfo g_emlrtRSI = {
    34,          /* lineNo */
    "quat2rotm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/shared/robotics/robotutilsint/+robotics/"
    "+internal/quat2rotm.m" /* pathName */
};

static emlrtRSInfo h_emlrtRSI = {
    35,          /* lineNo */
    "quat2rotm", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/shared/robotics/robotutilsint/+robotics/"
    "+internal/quat2rotm.m" /* pathName */
};

static emlrtRSInfo i_emlrtRSI = {
    15,              /* lineNo */
    "normalizeRows", /* fcnName */
    "/usr/local/MATLAB/R2024a/toolbox/shared/robotics/robotutilsint/+robotics/"
    "+internal/normalizeRows.m" /* pathName */
};

static emlrtRTEInfo emlrtRTEI = {
    13,                                                            /* lineNo */
    9,                                                             /* colNo */
    "sqrt",                                                        /* fName */
    "/usr/local/MATLAB/R2024a/toolbox/eml/lib/matlab/elfun/sqrt.m" /* pName */
};

/* Function Definitions */
void quat2rotm(const emlrtStack *sp, const real_T q[4], real_T R[9])
{
  __m128d r;
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack st;
  real_T tempR[9];
  real_T normRowMatrix[4];
  real_T b_tempR_tmp;
  real_T c_tempR_tmp;
  real_T d_tempR_tmp;
  real_T e_tempR_tmp;
  real_T tempR_tmp;
  real_T x;
  int32_T k;
  st.prev = sp;
  st.tls = sp->tls;
  st.site = &d_emlrtRSI;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  b_st.site = &e_emlrtRSI;
  r = _mm_loadu_pd(&q[0]);
  _mm_storeu_pd(&normRowMatrix[0], _mm_mul_pd(r, r));
  r = _mm_loadu_pd(&q[2]);
  _mm_storeu_pd(&normRowMatrix[2], _mm_mul_pd(r, r));
  x = sumColumnB(normRowMatrix);
  c_st.site = &i_emlrtRSI;
  if (x < 0.0) {
    emlrtErrorWithMessageIdR2018a(
        &c_st, &emlrtRTEI, "Coder:toolbox:ElFunDomainError",
        "Coder:toolbox:ElFunDomainError", 3, 4, 4, "sqrt");
  }
  x = muDoubleScalarSqrt(x);
  r = _mm_set1_pd(1.0 / x);
  _mm_storeu_pd(&normRowMatrix[0], _mm_mul_pd(_mm_loadu_pd(&q[0]), r));
  _mm_storeu_pd(&normRowMatrix[2], _mm_mul_pd(_mm_loadu_pd(&q[2]), r));
  b_st.site = &f_emlrtRSI;
  b_st.site = &f_emlrtRSI;
  b_st.site = &g_emlrtRSI;
  b_st.site = &g_emlrtRSI;
  b_st.site = &h_emlrtRSI;
  b_st.site = &h_emlrtRSI;
  x = normRowMatrix[3] * normRowMatrix[3];
  tempR_tmp = normRowMatrix[2] * normRowMatrix[2];
  tempR[0] = 1.0 - 2.0 * (tempR_tmp + x);
  b_tempR_tmp = normRowMatrix[1] * normRowMatrix[2];
  c_tempR_tmp = normRowMatrix[0] * normRowMatrix[3];
  tempR[1] = 2.0 * (b_tempR_tmp - c_tempR_tmp);
  d_tempR_tmp = normRowMatrix[1] * normRowMatrix[3];
  e_tempR_tmp = normRowMatrix[0] * normRowMatrix[2];
  tempR[2] = 2.0 * (d_tempR_tmp + e_tempR_tmp);
  tempR[3] = 2.0 * (b_tempR_tmp + c_tempR_tmp);
  b_tempR_tmp = normRowMatrix[1] * normRowMatrix[1];
  tempR[4] = 1.0 - 2.0 * (b_tempR_tmp + x);
  x = normRowMatrix[2] * normRowMatrix[3];
  c_tempR_tmp = normRowMatrix[0] * normRowMatrix[1];
  tempR[5] = 2.0 * (x - c_tempR_tmp);
  tempR[6] = 2.0 * (d_tempR_tmp - e_tempR_tmp);
  tempR[7] = 2.0 * (x + c_tempR_tmp);
  tempR[8] = 1.0 - 2.0 * (b_tempR_tmp + tempR_tmp);
  memcpy(&R[0], &tempR[0], 9U * sizeof(real_T));
  for (k = 0; k < 3; k++) {
    R[k] = tempR[3 * k];
    R[k + 3] = tempR[3 * k + 1];
    R[k + 6] = tempR[3 * k + 2];
  }
}

/* End of code generation (quat2rotm.c) */
