/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_pig_eucld_dynamics_mex.c
 *
 * Code generation for function '_coder_pig_eucld_dynamics_mex'
 *
 */

/* Include files */
#include "_coder_pig_eucld_dynamics_mex.h"
#include "_coder_pig_eucld_dynamics_api.h"
#include "pig_eucld_dynamics_data.h"
#include "pig_eucld_dynamics_initialize.h"
#include "pig_eucld_dynamics_terminate.h"
#include "rt_nonfinite.h"

/* Function Definitions */
void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs,
                 const mxArray *prhs[])
{
  mexAtExit(&pig_eucld_dynamics_atexit);
  /* Module initialization. */
  pig_eucld_dynamics_initialize();
  /* Dispatch the entry-point. */
  pig_eucld_dynamics_mexFunction(nlhs, plhs, nrhs, prhs);
  /* Module termination. */
  pig_eucld_dynamics_terminate();
}

emlrtCTX mexFunctionCreateRootTLS(void)
{
  emlrtCreateRootTLSR2021a(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1,
                           NULL);
  return emlrtRootTLSGlobal;
}

void pig_eucld_dynamics_mexFunction(int32_T nlhs, mxArray *plhs[1],
                                    int32_T nrhs, const mxArray *prhs[4])
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  const mxArray *outputs;
  st.tls = emlrtRootTLSGlobal;
  /* Check for proper number of arguments. */
  if (nrhs != 4) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:WrongNumberOfInputs", 5, 12, 4, 4,
                        18, "pig_eucld_dynamics");
  }
  if (nlhs > 1) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:TooManyOutputArguments", 3, 4, 18,
                        "pig_eucld_dynamics");
  }
  /* Call the function. */
  pig_eucld_dynamics_api(prhs, &outputs);
  /* Copy over outputs to the caller. */
  emlrtReturnArrays(1, &plhs[0], &outputs);
}

/* End of code generation (_coder_pig_eucld_dynamics_mex.c) */
