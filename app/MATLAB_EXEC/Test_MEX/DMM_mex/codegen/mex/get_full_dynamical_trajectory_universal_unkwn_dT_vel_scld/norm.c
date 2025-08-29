/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * norm.c
 *
 * Code generation for function 'norm'
 *
 */

/* Include files */
#include "norm.h"
#include "rt_nonfinite.h"
#include "mwmathutil.h"

/* Function Definitions */
real_T b_norm(const real_T x[16])
{
  real_T y;
  int32_T j;
  boolean_T exitg1;
  y = 0.0;
  j = 0;
  exitg1 = false;
  while ((!exitg1) && (j < 4)) {
    real_T s;
    int32_T s_tmp;
    s_tmp = j << 2;
    s = ((muDoubleScalarAbs(x[s_tmp]) + muDoubleScalarAbs(x[s_tmp + 1])) +
         muDoubleScalarAbs(x[s_tmp + 2])) +
        muDoubleScalarAbs(x[s_tmp + 3]);
    if (muDoubleScalarIsNaN(s)) {
      y = rtNaN;
      exitg1 = true;
    } else {
      if (s > y) {
        y = s;
      }
      j++;
    }
  }
  return y;
}

/* End of code generation (norm.c) */
