/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex.c
 *
 * Code generation for function
 * '_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex'
 *
 */

/* Include files */
#include "_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex.h"
#include "_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_api.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_data.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_initialize.h"
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_terminate.h"
#include "rt_nonfinite.h"

/* Function Definitions */
void get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mexFunction(
    int32_T nlhs, mxArray *plhs[7], int32_T nrhs, const mxArray *prhs[7])
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  const mxArray *outputs[7];
  int32_T i;
  st.tls = emlrtRootTLSGlobal;
  /* Check for proper number of arguments. */
  if (nrhs != 7) {
    emlrtErrMsgIdAndTxt(
        &st, "EMLRT:runTime:WrongNumberOfInputs", 5, 12, 7, 4, 57,
        "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld");
  }
  if (nlhs > 7) {
    emlrtErrMsgIdAndTxt(
        &st, "EMLRT:runTime:TooManyOutputArguments", 3, 4, 57,
        "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld");
  }
  /* Call the function. */
  c_get_full_dynamical_trajectory(prhs, nlhs, outputs);
  /* Copy over outputs to the caller. */
  if (nlhs < 1) {
    i = 1;
  } else {
    i = nlhs;
  }
  emlrtReturnArrays(i, &plhs[0], &outputs[0]);
}

void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs,
                 const mxArray *prhs[])
{
  mexAtExit(&get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_atexit);
  /* Module initialization. */
  get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_initialize();
  /* Dispatch the entry-point. */
  get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mexFunction(
      nlhs, plhs, nrhs, prhs);
  /* Module termination. */
  get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_terminate();
}

emlrtCTX mexFunctionCreateRootTLS(void)
{
  emlrtCreateRootTLSR2022a(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1,
                           NULL, "UTF-8", true);
  return emlrtRootTLSGlobal;
}

/* End of code generation
 * (_coder_get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_mex.c) */
