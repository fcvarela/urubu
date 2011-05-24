#ifndef AHRS_QUAT_FAST_EKF_H
#define AHRS_QUAT_FAST_EKF_H

#include <inttypes.h>
#define AXIS_X  0
#define AXIS_Y  1
#define AXIS_Z  2

#define AXIS_P 0
#define AXIS_Q 1
#define AXIS_R 2

/* ekf state : quaternion and gyro biases */
extern double afe_q0, afe_q1, afe_q2, afe_q3;
extern double afe_bias_p, afe_bias_q, afe_bias_r;
/* we maintain unbiased rates */
extern double afe_p, afe_q, afe_r;
/* we maintain eulers angles */
extern double afe_phi, afe_theta, afe_psi;

extern double afe_P[7][7]; /* covariance */

extern void afe_init( const double mag, const double* accel, const double* gyro );
extern void afe_predict( const double* gyro );
extern void afe_update_phi( const double* accel);
extern void afe_update_theta( const double* accel);
extern void afe_update_psi( const double mag);

#endif /* AHRS_QUAT_FAST_EKF_H_H */
