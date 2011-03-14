function simd_add_dsp48e_init_xblock(mode, n_bits_a, bin_pt_a, n_bits_b, bin_pt_b, full_precision, n_bits_c, bin_pt_c, quantization, overflow, cast_latency)
%% inports
a_re = xInport('a_re');
a_im = xInport('a_im');
b_re = xInport('b_re');
b_im = xInport('b_im');

%% outports
c_re = xOutport('c_re');
c_im = xOutport('c_im');

%% diagram

% block: dsp48e_pfb_test3/caddsub_dsp48e/DSP48E
Reinterpret_A_out1 = xSignal;
Reinterpret_B_out1 = xSignal;
Reinterpret_C_out1 = xSignal;
opmode_out1 = xSignal;
alumode_out1 = xSignal;
carryin_out1 = xSignal;
carryinsel_out1 = xSignal;
DSP48E_out1 = xSignal;
slice_c_im_out1 = xSignal;
realign_b_re_out1 = xSignal;
realign_a_re_out1 = xSignal;
realign_a_im_out1 = xSignal;
reinterp_a_re_out1 = xSignal;
reinterp_c_re_out1 = xSignal;
reinterp_c_im_out1 = xSignal;
concat_b_out1 = xSignal;
concat_a_out1 = xSignal;
Slice_B_out1 = xSignal;
Slice_A_out1 = xSignal;
reinterp_a_im_out1 = xSignal;
reinterp_b_re_out1 = xSignal;
reinterp_b_im_out1 = xSignal;
realign_b_im_out1 = xSignal;
slice_c_re_out1 = xSignal;

max_non_frac = max(n_bits_a - bin_pt_a, n_bits_b - bin_pt_b);
max_bin_pt = max(bin_pt_a, bin_pt_b);
bin_pt_tmp = 24 - (max_non_frac + 2);

if strcmp(full_precision, 'on'),
  n_bits_out = max_non_frac + max_bin_pt + 1;
  bin_pt_out = max_bin_pt;
else,
  n_bits_out = n_bits_c;
  bin_pt_out = bin_pt_c;
end


DSP48E = xBlock(struct('source', 'DSP48E', 'name', 'DSP48E'), ...
                       struct('use_creg', 'on', ...
                              'addsub_mode', 'TWO24'), ...
                       {Reinterpret_A_out1, Reinterpret_B_out1, Reinterpret_C_out1, opmode_out1, alumode_out1, carryin_out1, carryinsel_out1}, ...
                       {DSP48E_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Reinterpret_A
Reinterpret_A = xBlock(struct('source', 'Reinterpret', 'name', 'Reinterpret_A'), ...
                              struct('force_arith_type', 'on', ...
                                     'arith_type', 'Signed  (2''s comp)', ...
                                     'force_bin_pt', 'on'), ...
                              {Slice_A_out1}, ...
                              {Reinterpret_A_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Reinterpret_B
Reinterpret_B = xBlock(struct('source', 'Reinterpret', 'name', 'Reinterpret_B'), ...
                              struct('force_arith_type', 'on', ...
                                     'arith_type', 'Signed  (2''s comp)', ...
                                     'force_bin_pt', 'on'), ...
                              {Slice_B_out1}, ...
                              {Reinterpret_B_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Reinterpret_C
Reinterpret_C = xBlock(struct('source', 'Reinterpret', 'name', 'Reinterpret_C'), ...
                              struct('force_arith_type', 'on', ...
                                     'arith_type', 'Signed  (2''s comp)', ...
                                     'force_bin_pt', 'on'), ...
                              {concat_a_out1}, ...
                              {Reinterpret_C_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Slice_A
Slice_A = xBlock(struct('source', 'Slice', 'name', 'Slice_A'), ...
                        struct('nbits', 30), ...
                        {concat_b_out1}, ...
                        {Slice_A_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/Slice_B
Slice_B = xBlock(struct('source', 'Slice', 'name', 'Slice_B'), ...
                        struct('nbits', 18, ...
                               'mode', 'Lower Bit Location + Width'), ...
                        {concat_b_out1}, ...
                        {Slice_B_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/alumode
alumode = xBlock(struct('source', 'Constant', 'name', 'alumode'), ...
                        struct('arith_type', 'Unsigned', ...
                               'const', 0, ...
                               'n_bits', 4, ...
                               'bin_pt', 0), ...
                        {}, ...
                        {alumode_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/carryin
carryin = xBlock(struct('source', 'Constant', 'name', 'carryin'), ...
                        struct('arith_type', 'Unsigned', ...
                               'const', 0, ...
                               'n_bits', 1, ...
                               'bin_pt', 0), ...
                        {}, ...
                        {carryin_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/carryinsel
carryinsel = xBlock(struct('source', 'Constant', 'name', 'carryinsel'), ...
                           struct('arith_type', 'Unsigned', ...
                                  'const', 0, ...
                                  'n_bits', 3, ...
                                  'bin_pt', 0), ...
                           {}, ...
                           {carryinsel_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/cast_c_im
cast_c_im = xBlock(struct('source', 'Convert', 'name', 'cast_c_im'), ...
                          struct('n_bits', n_bits_out, ...
                                 'bin_pt', bin_pt_c, ...
                                 'pipeline', 'on'), ...
                          {reinterp_c_im_out1}, ...
                          {c_im});

% block: dsp48e_pfb_test3/caddsub_dsp48e/cast_c_re
cast_c_re = xBlock(struct('source', 'Convert', 'name', 'cast_c_re'), ...
                          struct('n_bits', n_bits_out, ...
                                 'bin_pt', bin_pt_c, ...
                                 'pipeline', 'on'), ...
                          {reinterp_c_re_out1}, ...
                          {c_re});

% block: dsp48e_pfb_test3/caddsub_dsp48e/concat_a
concat_a = xBlock(struct('source', 'Concat', 'name', 'concat_a'), ...
                         [], ...
                         {reinterp_a_re_out1, reinterp_a_im_out1}, ...
                         {concat_a_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/concat_b
concat_b = xBlock(struct('source', 'Concat', 'name', 'concat_b'), ...
                         [], ...
                         {reinterp_b_re_out1, reinterp_b_im_out1}, ...
                         {concat_b_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/opmode
opmode = xBlock(struct('source', 'Constant', 'name', 'opmode'), ...
                       struct('arith_type', 'Unsigned', ...
                              'const', 51, ...
                              'n_bits', 7, ...
                              'bin_pt', 0), ...
                       {}, ...
                       {opmode_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/realign_a_im
realign_a_im = xBlock(struct('source', 'Convert', 'name', 'realign_a_im'), ...
                             struct('n_bits', 24, ...
                                    'bin_pt', bin_pt_tmp, ...
                                    'pipeline', 'on'), ...
                             {a_im}, ...
                             {realign_a_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/realign_a_re
realign_a_re = xBlock(struct('source', 'Convert', 'name', 'realign_a_re'), ...
                             struct('n_bits', 24, ...
                                    'bin_pt', bin_pt_tmp, ...
                                    'pipeline', 'on'), ...
                             {a_re}, ...
                             {realign_a_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/realign_b_im
realign_b_im = xBlock(struct('source', 'Convert', 'name', 'realign_b_im'), ...
                             struct('n_bits', 24, ...
                                    'bin_pt', bin_pt_tmp, ...
                                    'pipeline', 'on'), ...
                             {b_im}, ...
                             {realign_b_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/realign_b_re
realign_b_re = xBlock(struct('source', 'Convert', 'name', 'realign_b_re'), ...
                             struct('n_bits', 24, ...
                                    'bin_pt', bin_pt_tmp, ...
                                    'pipeline', 'on'), ...
                             {b_re}, ...
                             {realign_b_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_a_im
reinterp_a_im = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_a_im'), ...
                              struct('force_arith_type', 'on', ...
                                     'force_bin_pt', 'on'), ...
                              {realign_a_im_out1}, ...
                              {reinterp_a_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_a_re
reinterp_a_re = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_a_re'), ...
                              struct('force_arith_type', 'on', ...
                                     'force_bin_pt', 'on'), ...
                              {realign_a_re_out1}, ...
                              {reinterp_a_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_b_im
reinterp_b_im = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_b_im'), ...
                              struct('force_arith_type', 'on', ...
                                     'force_bin_pt', 'on'), ...
                              {realign_b_im_out1}, ...
                              {reinterp_b_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_b_re
reinterp_b_re = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_b_re'), ...
                              struct('force_arith_type', 'on', ...
                                     'force_bin_pt', 'on'), ...
                              {realign_b_re_out1}, ...
                              {reinterp_b_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_c_im
reinterp_c_im = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_c_im'), ...
                              struct('force_arith_type', 'on', ...
                                     'arith_type', 'Signed  (2''s comp)', ...
                                     'force_bin_pt', 'on', ...
                                     'bin_pt', bin_pt_tmp), ...
                              {slice_c_im_out1}, ...
                              {reinterp_c_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/reinterp_c_re
reinterp_c_re = xBlock(struct('source', 'Reinterpret', 'name', 'reinterp_c_re'), ...
                              struct('force_arith_type', 'on', ...
                                     'arith_type', 'Signed  (2''s comp)', ...
                                     'force_bin_pt', 'on', ...
                                     'bin_pt', bin_pt_tmp), ...
                              {slice_c_re_out1}, ...
                              {reinterp_c_re_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/slice_c_im
slice_c_im = xBlock(struct('source', 'Slice', 'name', 'slice_c_im'), ...
                           struct('nbits', 24, ...
                                  'mode', 'Lower Bit Location + Width'), ...
                           {DSP48E_out1}, ...
                           {slice_c_im_out1});

% block: dsp48e_pfb_test3/caddsub_dsp48e/slice_c_re
slice_c_re = xBlock(struct('source', 'Slice', 'name', 'slice_c_re'), ...
                           struct('nbits', 24, ...
                                  'mode', 'Lower Bit Location + Width', ...
                                  'bit0', 24), ...
                           {DSP48E_out1}, ...
                           {slice_c_re_out1});



end

