/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * pig_dynamics_initialize.c
 *
 * Code generation for function 'pig_dynamics_initialize'
 *
 */

/* Include files */
#include "pig_dynamics_initialize.h"
#include "_coder_pig_dynamics_mex.h"
#include "pig_dynamics_data.h"
#include "rt_nonfinite.h"

/* Function Definitions */
void pig_dynamics_initialize(void)
{
  static const volatile char_T *emlrtBreakCheckR2012bFlagVar = NULL;
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mex_InitInfAndNan();
  mexFunctionCreateRootTLS();
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2012b();
  st.tls = emlrtRootTLSGlobal;
  emlrtClearAllocCountR2012b(&st, false, 0U, NULL);
  emlrtEnterRtStackR2012b(&st);
  emlrtLicenseCheckR2012b(&st, (const char_T *)"phased_array_system_toolbox",
                          2);
  emlrtLicenseCheckR2012b(&st, (const char_T *)"signal_blocks", 2);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (pig_dynamics_initialize.c) */
