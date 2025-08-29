/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld.h
 *
 * Code generation for function
 * 'get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld'
 *
 */

#pragma once

/* Include files */
#include "get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld_types.h"
#include "rtwtypes.h"
#include "emlrt.h"
#include "mex.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Function Declarations */
void get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld(
    const emlrtStack *sp, const real_T new_agb_j[21],
    const emxArray_real_T *indices, const emxArray_real_T *g_all,
    const emxArray_real_T *w_all, real_T downsampling,
    const real_T start_gps[3], const real_T best_initial_orientation[4],
    emxArray_real_T *q_dot, emxArray_real_T *q, emxArray_real_T *v_dot,
    emxArray_real_T *v, emxArray_real_T *p_gen, emxArray_real_T *odo_gen,
    emxArray_real_T *acc_ef);

/* End of code generation
 * (get_full_dynamical_trajectory_universal_unkwn_dT_vel_scld.h) */
