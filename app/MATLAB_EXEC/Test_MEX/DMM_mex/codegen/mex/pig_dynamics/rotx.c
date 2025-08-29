/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * rotx.c
 *
 * Code generation for function 'rotx'
 *
 */

/* Include files */
#include "rotx.h"
#include "cosd.h"
#include "pig_dynamics_data.h"
#include "rt_nonfinite.h"
#include "sind.h"
#include "mwmathutil.h"

/* Variable Definitions */
static emlrtRSInfo sb_emlrtRSI = {
    30,     /* lineNo */
    "rotx", /* fcnName */
    "C:\\Program Files\\MATLAB\\R2021b\\toolbox\\phased\\phased\\rotx.m" /* pathName
                                                                          */
};

/* Function Definitions */
void rotx(const emlrtStack *sp, real_T alpha, real_T rotmat[9])
{
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack st;
  real_T b_rotmat_tmp;
  real_T rotmat_tmp;
  st.prev = sp;
  st.tls = sp->tls;
  st.site = &sb_emlrtRSI;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  b_st.site = &qb_emlrtRSI;
  c_st.site = &rb_emlrtRSI;
  if (muDoubleScalarIsInf(alpha) || muDoubleScalarIsNaN(alpha)) {
    emlrtErrorWithMessageIdR2018a(
        &c_st, &b_emlrtRTEI, "Coder:toolbox:ValidateattributesexpectedFinite",
        "MATLAB:rotx:expectedFinite", 3, 4, 5, "ALPHA");
  }
  c_st.site = &rb_emlrtRSI;
  if (muDoubleScalarIsNaN(alpha)) {
    emlrtErrorWithMessageIdR2018a(
        &c_st, &c_emlrtRTEI, "Coder:toolbox:ValidateattributesexpectedNonNaN",
        "MATLAB:rotx:expectedNonNaN", 3, 4, 5, "ALPHA");
  }
  rotmat_tmp = alpha;
  b_sind(&rotmat_tmp);
  b_rotmat_tmp = alpha;
  b_cosd(&b_rotmat_tmp);
  rotmat[0] = 1.0;
  rotmat[3] = 0.0;
  rotmat[6] = 0.0;
  rotmat[1] = 0.0;
  rotmat[4] = b_rotmat_tmp;
  rotmat[7] = -rotmat_tmp;
  rotmat[2] = 0.0;
  rotmat[5] = rotmat_tmp;
  rotmat[8] = b_rotmat_tmp;
}

/* End of code generation (rotx.c) */
