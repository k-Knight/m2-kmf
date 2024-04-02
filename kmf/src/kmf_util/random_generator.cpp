#include "kmf_util.hpp"

#include <random>
#include <vector>
#include <stdlib.h>

std::mt19937 gen(std::random_device{}());
std::uniform_real_distribution<float> uniform_float_distr(0, 1);

extern "C" {
    float generate_radom_number() {
        return uniform_float_distr(gen);
    }

    int generate_uniform_from_to(int min, int max) {
        if (min >= max)
            return max;

        std::uniform_int_distribution<int> distr(min, max);
        return distr(gen);
    }

    bool generate_bernoulli(float p) {
        if (p < 0.0 || p > 1.0)
            return false;

        std::bernoulli_distribution distr(p);
        return distr(gen);
    }

    int generate_my_random_from_to(int min, int max) {
        if (min >= max)
            return max;

        const int prob_max = ((max - min) / 2) + 1;
        const int mid = min + prob_max - 1;
        max++;
        const bool odd = (max - min) % 2;
        const int num = max - min + (odd ? 1 : 0);
        const double prob_sum = double(2) * (num / double(4)) * double(2 + num / 2 - (odd ? 2 : 1));

        std::discrete_distribution<int> distr(max - min, min, max,
            [mid, odd, prob_max, prob_sum](int val) {
                int prob = prob_max;

                prob -= abs(val - mid) - ((!odd && val > mid) ? 1 : 0);

                return double(prob) / prob_sum;
            }
        );

        return distr(gen) + min;
    }
}