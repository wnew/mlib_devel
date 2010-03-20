function finedelay_fstop_prog_init(blk, varargin)
% Initialize and configure the Fine Delay + Fringe Stop block 
% Mekhala, GMRT, India.
%
% %
% blk = The block to configure.
% varargin = {'varname', 'value', ...} pairs
% 
% Declare any default values for arguments you might like.
 
defaults = {'n_input',2,'fft_len',1024,'fft_bits',18,'theta_bits',14,'sine_cos_bits',18,'fft_cycle_bits',17};
 
% if parameter is changed then only it will redraw otherwise will exit
if same_state(blk, 'defaults', defaults, varargin{:}), return, end
 
% Checks whether the block selected is correct with this called function.
check_mask_type(blk, 'finedelay_fstop_prog');
 
%Sets the variable to the sub-blocks (scripted ones), also checks whether
%to update or prevent from any update
munge_block(blk, varargin{:});
 
% sets the variable needed
n_input = get_var ('n_input','defaults', defaults, varargin{:});
fft_len = get_var('fft_len', 'defaults', defaults, varargin{:});
fft_bits = get_var('fft_bits', 'defaults', defaults, varargin{:});
theta_bits= get_var('theta_bits', 'defaults', defaults, varargin{:});
sine_cos_bits = get_var('sine_cos_bits', 'defaults', defaults,varargin{:});
fft_cycle_bits = get_var('fft_cycle_bits', 'defaults', defaults,varargin{:});
 
% Begin redrawing
 
delete_lines(blk);
 
% Drawing the fixed blocks in the design.Includes the sync delays at the top
 
    reuse_block(blk,'sync_delay','casper_library/Delays/sync_delay',...
                'DelayLen', '3+4+2', ...
                'Position',[600 49 645 81]);
    
%  %%%%%%%%%% Drawing the blocks which are replicated depending upon the
% %  %%%%%%%%%% number of inputs.
 y1 = 181;
 y2 = 214;
 for i=1:n_input
     name = ['Fract_Theta_Reg',num2str(i)];
     reuse_block(blk,name,'xbsIndex_r4/Register',...
            'Position',[135 y1+((i-1)*405) 175 y2+((i-1)*405)],...
            'en', 'on');
        
     name = ['FFT_Chnl_Cnt',num2str((i*2-1))];
     reuse_block(blk,name,'xbsIndex_r4/Counter',...
            'Position',[135 y1+51+((i-1)*405) 175 y2+34+((i-1)*405)],...
            'cnt_type', 'Free Running',...
            'n_bits',num2str(ceil(log2(fft_len))),...
            'bin_pt', '0',...
            'arith_type', 'Unsigned',...
            'start_count', num2str(i-1),...
            'cnt_by_val', num2str(n_input),...
            'operation', 'Up',...
            'rst', 'on');
        
     name = ['Logical',num2str(i)];
     reuse_block(blk,name,'xbsIndex_r4/Logical',...
            'Position',[135 y1+174+((i-1)*405) 170 y2+161+((i-1)*405)],...
            'logical_function', 'OR',...
            'inputs', '2',...
            'precision', 'Full',...
            'arith_type', 'Unsigned',...
            'n_bits', '1',...
            'bin_pt', '0',...
            'align_bp', 'on',...
            'latency', '0');
        
     name = ['FFT_Chnl_Cnt',num2str(i*2)];
     reuse_block(blk,name,'xbsIndex_r4/Counter',...
            'Position',[135 y1+202+((i-1)*405) 170 y2+193+((i-1)*405)],...
            'cnt_type', 'Free Running',...
            'n_bits',num2str(ceil(log2(fft_len/n_input))),...
            'bin_pt', '0',...
            'arith_type', 'Unsigned',...
            'start_count', '0',...
            'cnt_by_val','1',...
            'operation', 'Up',...
            'rst', 'on');
     
    name = ['FFT_Length',num2str(i)];
    reuse_block(blk,name,'xbsIndex_r4/Constant',...
           'Position',[135 y1+234+((i-1)*405) 170 y2+221+((i-1)*405)],... 
           'const',num2str((fft_len/n_input)-1),...
           'arith_type','Unsigned',...
           'n_bits',num2str(ceil(log2(fft_len/n_input))),...
           'bin_pt', '0',...
           'explicit_period','on',...
            'period','1');
               
            
     name = ['Fract_Theta_Mult',num2str(i)];
     reuse_block(blk,name,'xbsIndex_r4/Mult',...
            'Position',[210 y1-3+((i-1)*406) 255 y2+48+((i-1)*404)],...
            'precision', 'User Defined',...
            'arith_type', 'Unsigned',...
            'n_bits',num2str(theta_bits),...
            'bin_pt', '0',...
            'use_embedded', 'on',...
            'pipeline', 'on',...
            'use_rpm', 'on');
     
     name = ['pulse_ext', num2str(i)];
     reuse_block(blk,name,'casper_library/Misc/pulse_ext',...
                   'Position', [210 y1+100+((i-1)*410) 245 y2+85+((i-1)*410)],...
                   'pulse_len', '2^27');         
            
     
     name = ['Convert', num2str((i*3)-2)];
     reuse_block(blk,name,'xbsIndex_r4/Convert',...
                    'Position', [210 y1+175+((i-1)*405) 245 y2+160+((i-1)*405)],...
                    'arith_type', 'Boolean');    
     
    name = ['Relational', num2str((i*2)-1)];                
    reuse_block(blk,name,'xbsIndex_r4/Relational',...
            'Position', [210 y1+214+((i-1)*405) 245 y2+216+((i-1)*405)],...
             'mode', 'a=b',...
             'latency', '0');                
                    
    name = ['Logical',num2str(i+n_input)];
    reuse_block(blk,name,'xbsIndex_r4/Logical',...
            'Position',[290 y1+94+((i-1)*410) 325 y2+81+((i-1)*410)],...
            'logical_function', 'AND',...
            'inputs', '2',...
            'precision', 'Full',...
            'arith_type', 'Unsigned',...
            'n_bits', '1',...
            'bin_pt', '0',...
            'align_bp', 'on',...
            'latency', '0');     
        
   name = ['FFT_Cycle_Cnt',num2str(i)];
   reuse_block(blk,name,'xbsIndex_r4/Counter',...
            'Position',[290 y1+213+((i-1)*405) 330 y2+205+((i-1)*405)],...
            'cnt_type', 'Free Running',...
            'n_bits',num2str(fft_cycle_bits),...
            'bin_pt', '0',...
            'arith_type', 'Unsigned',...
            'cnt_by_val', '1',...
            'operation', 'Up',...
            'rst', 'on',...
            'en', 'on');          
             
    name = ['Fringe_Rate_Reg',num2str(i)];
    reuse_block(blk,name,'xbsIndex_r4/Register',...
            'Position',[290 (y1+256+((i-1)*405)) 330 (y2+259+((i-1)*405))],...
            'en', 'on');  
        
   name = ['Delay', num2str(i)];
   reuse_block(blk,name,'xbsIndex_r4/Delay',...
              'latency', '1',...
              'position',[355 y1+94+((i-1)*410) 390 y2+81+((i-1)*410)]); 
   
   name = ['Delay', num2str(i+n_input)];
   reuse_block(blk,name,'xbsIndex_r4/Delay',...
              'latency', '1',...
              'position',[355 y1+129+((i-1)*410) 390 y2+116+((i-1)*410)]); 
                 
   name = ['Relational', num2str(i*2)];                
   reuse_block(blk,name,'xbsIndex_r4/Relational',...
            'Position',[355 y1+235+((i-1)*405) 390 y2+240+((i-1)*405)],...
             'mode', 'a=b',...
             'latency', '0');            
  
   name = ['Logical',num2str(i+ (2*n_input))];
   reuse_block(blk,name,'xbsIndex_r4/Logical',...
            'Position',[470 y1+134+((i-1)*410) 505 y2+121+((i-1)*410)],...
            'logical_function', 'OR',...
            'inputs', '2',...
            'precision', 'Full',...
            'arith_type', 'Unsigned',...
            'n_bits', '1',...
            'bin_pt', '0',...
            'align_bp', 'on',...
            'latency', '0');     
             
  name = ['posedge', num2str(i)];                
  reuse_block(blk,name,'casper_library/Misc/posedge',...
            'Position',[415 y1+244+((i-1)*405) 450 y2+231+((i-1)*405)]);           
        
    name = ['fstop_sel',num2str(i)];
    reuse_block(blk,name,'xbsIndex_r4/Constant',...
           'Position',[560 y1+146+((i-1)*410) 595 y2+129+((i-1)*410)],...
           'const','0',...
           'arith_type','Unsigned',...
           'n_bits',num2str(fft_cycle_bits),...
           'bin_pt', '0',...
           'explicit_period','on',...
            'period','1');         
            
 name = ['Relational_sel', num2str(i)];                
   reuse_block(blk,name,'xbsIndex_r4/Relational',...
            'Position',[615 y1+147+((i-1)*410) 645 y2+138+((i-1)*410)],...
             'mode', 'a!=b',...
             'latency', '0'); 
            
   name = ['fstop_mux', num2str(i)];                
   reuse_block(blk,name,'xbsIndex_r4/Mux',...
            'Position',[660 y1+146+((i-1)*410) 675 y2+189+((i-1)*410)],...
             'inputs', '2',...
             'precision', 'Full');
            
            
  
   name = ['Fringe_Theta_Cnt',num2str(i)];
   reuse_block(blk,name,'xbsIndex_r4/Counter',...
            'Position',[720 y1+96+((i-1)*410) 750 y2+119+((i-1)*410)],...
            'cnt_type', 'Free Running',...
            'n_bits',num2str(theta_bits),...
            'bin_pt', '0',...
            'arith_type', 'Unsigned',...
            'cnt_by_val', '1',...
            'operation', 'Up',...
            'explicit_period', 'on',...
            'period', '1',...
            'load_pin', 'on',...
            'en', 'on');     
   
   name = ['Delay', num2str(i+(2*n_input))];
   reuse_block(blk,name,'xbsIndex_r4/Delay',...
              'latency', '2',...
              'position',[770 y1+111+((i-1)*410) 790 y2+104+((i-1)*410)]); 
 
            
            
   name = ['Fract_Fringe_Adder', num2str(i)];
   reuse_block(blk,name,'xbsIndex_r4/AddSub',...
               'Position',[815 y1+33+((i-1)*405) 845 y2+27+((i-1)*405)],...
               'mode', 'Addition',...
               'precision', 'User Defined',...
               'arith_type', 'Unsigned',...
               'n_bits', num2str(theta_bits),...
               'bin_pt', '0',...
               'quantization', 'Truncate',...
               'overflow', 'Wrap',...
               'latency', '2');        
            
   
   name = ['SineCosine', num2str(i)];
   reuse_block(blk,name,'casper_library/Downconverter/sincos',...
               'Position',[875 y1+38+((i-1)*405) 920 y2+27+((i-1)*405)],...        
               'func', 'sine and cosine',...
               'neg_sin','off',...
               'neg_cos', 'off',...
               'bit_width', num2str(sine_cos_bits),...
               'depth_bits', num2str(theta_bits),...
               'bram_latency', '2',...
               'symmetric', 'off', ...
               'handle_sync', 'off');
           
   
   name = ['Input_Del', num2str(i)];
   reuse_block(blk,name,'xbsIndex_r4/Delay',...
              'latency', '7',...
              'position',[980 y1+6+((i-1)*405) 1010 y2-1+((i-1)*405)]);         
               
   name = ['c_to_ri', num2str(i)];
   reuse_block(blk,name,'casper_library/Misc/c_to_ri',...
               'position',[1035 y1+2+((i-1)*405) 1060 y2-2+((i-1)*405)],...
               'n_bits', num2str(fft_bits),...
               'bin_pt',num2str(fft_bits-1));    
               
 
 
    name = ['cmult', num2str(i)];
    reuse_block(blk,name,'casper_library/Multipliers/cmult_4bit_hdl',...
                'Position',[1105 y1-1+((i-1)*405) 1150 y2+31+((i-1)*405)],...
                'mult_latency', '2',...
                'add_latency', '0') ; 
            
    name = ['Convert', num2str((i*3)-1)];
    reuse_block(blk,name,'xbsIndex_r4/Convert',...
                'Position',[1185 y1+4+((i-1)*405) 1230 y2+1+((i-1)*405)],...
                'arith_type', 'Signed',...
                'n_bits', 'fft_bits',...
                'bin_pt', 'fft_bits-1',...
                'latency', '0',...
                'ShowName', 'off') ;        
    
                
    name = ['Convert', num2str(i*3)];
    reuse_block(blk,name,'xbsIndex_r4/Convert',...
                'Position',[1185 y1+34+((i-1)*405) 1230 y2+31+((i-1)*405)],...
                'arith_type', 'Signed',...
                'n_bits', 'fft_bits',...
                'bin_pt', 'fft_bits-1',...
                'latency', '0',...
                'ShowName', 'off') ;   
            
                
   name = ['ri_to_c', num2str(i)];
   reuse_block(blk,name,'casper_library/Misc/ri_to_c',...
               'position',[1265 y1+2+((i-1)*405) 1300 y2+33+((i-1)*405)]);
                
 end
 
 
%             
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %%%%%%%% Drawing Input Output ports
% 
 
reuse_block(blk,'sync','built-in/Inport',...
                    'Position',[20 58 50 72]) ;
 
reuse_block(blk,'sync_out','built-in/Outport',...
                    'Position',[1050 58 1080 72]);
 
 
reuse_block(blk,'theta_fract','built-in/Inport',...
                    'Position',[20 183 50 197]);
                 
reuse_block(blk,'theta_fs','built-in/Inport',...
                'Position',[20 298 50 312]);  
            
reuse_block(blk,'fft_fs','built-in/Inport',...
                  'Position',[20 413 50 427]);
              
 
                  
reuse_block(blk,'en_theta_fs','built-in/Inport',...
                  'Position',[20 268 50 282]);
                 
                  
                  
y1 = 181;
y2 = 214;
                  
 for i=1:n_input      
     name = ['pol',num2str(i-1),'_in'];
     reuse_block(blk,name,'built-in/Inport',...
                    'Position',[925 y1+12+((i-1)*405) 955 y2-7+((i-1)*405)]) ;
 end
 
 
 y1 = 181;
 y2 = 214;
 for i=1:n_input 
     name = ['out',num2str(i-1)];
     reuse_block(blk,name,'built-in/Outport',...
                    'Position',[1325 y1+26+((i-1)*405) 1355 y2+8+((i-1)*405)]);
 end
          
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% % Add lines
 add_line(blk, 'sync/1', 'sync_delay/1', 'autorouting', 'on');
 add_line(blk, 'sync_delay/1', 'sync_out/1', 'autorouting', 'on');
 
for i= 1: n_input
    
     add_line(blk, 'sync/1', ['Fract_Theta_Reg',num2str(i),'/2'], 'autorouting', 'on');
     add_line(blk, 'sync/1', ['FFT_Chnl_Cnt',num2str(i*2-1),'/1'], 'autorouting', 'on');
     add_line(blk, 'sync/1', ['Logical',num2str(i+n_input),'/1'], 'autorouting', 'on');
 
     add_line(blk, 'sync/1', ['Logical',num2str(i),'/2'], 'autorouting', 'on');
     add_line(blk, 'sync/1', ['FFT_Chnl_Cnt',num2str(i*2),'/1'], 'autorouting', 'on');
     add_line(blk, 'sync/1', ['Fringe_Rate_Reg',num2str(i),'/2'], 'autorouting', 'on');
     add_line(blk, 'sync/1', ['Delay',num2str(i+n_input),'/1'], 'autorouting', 'on');
 
     add_line(blk, 'theta_fract/1', ['Fract_Theta_Reg',num2str(i),'/1'], 'autorouting', 'on');
     add_line(blk, ['Fract_Theta_Reg',num2str(i),'/1'],['Fract_Theta_Mult',num2str(i),'/1'], 'autorouting', 'on');
     add_line(blk, ['FFT_Chnl_Cnt',num2str(i*2-1),'/1'],['Fract_Theta_Mult',num2str(i),'/2'], 'autorouting', 'on');
 
    add_line(blk, 'en_theta_fs/1', ['pulse_ext',num2str(i),'/1'], 'autorouting', 'on');
 
     
    add_line(blk, ['posedge',num2str(i),'/1'],['Logical',num2str(i),'/1'], 'autorouting', 'on');
 
    add_line(blk, ['Logical',num2str(i),'/1'],['Convert',num2str((i*3)-2),'/1'], 'autorouting', 'on');
 
     
     add_line(blk, ['FFT_Chnl_Cnt',num2str(i*2),'/1'],['Relational',num2str((i*2)-1),'/1'], 'autorouting', 'on');
     add_line(blk, ['FFT_Length',num2str(i),'/1'],['Relational',num2str((i*2)-1),'/2'], 'autorouting', 'on');
 
     add_line(blk, ['Convert',num2str(i*3-2),'/1'],['FFT_Cycle_Cnt',num2str(i),'/1'], 'autorouting', 'on');
     add_line(blk, ['Relational',num2str(i*2-1),'/1'],['FFT_Cycle_Cnt',num2str(i),'/2'], 'autorouting', 'on');
 
     add_line(blk, 'fft_fs/1',['Fringe_Rate_Reg',num2str(i),'/1'], 'autorouting', 'on');
 
     add_line(blk,['FFT_Cycle_Cnt',num2str(i),'/1'],['Relational',num2str(i*2),'/1'],'autorouting', 'on');
     add_line(blk,['Fringe_Rate_Reg',num2str(i),'/1'],['Relational',num2str(i*2),'/2'],'autorouting', 'on');
 
     add_line(blk,['Relational',num2str(i*2),'/1'],['posedge',num2str(i),'/1'],'autorouting', 'on');
 
     add_line(blk, ['pulse_ext',num2str(i),'/1'],['Logical',num2str(i+n_input),'/2'], 'autorouting', 'on');
     add_line(blk,['Logical',num2str(i+n_input),'/1'], ['Delay',num2str(i),'/1'], 'autorouting', 'on');
 
     add_line(blk, ['Delay',num2str(i),'/1'],['Fringe_Theta_Cnt',num2str(i),'/1'], 'autorouting', 'on');
     add_line(blk, 'theta_fs/1',['Fringe_Theta_Cnt',num2str(i),'/2'], 'autorouting', 'on');
 
     add_line(blk, ['Delay',num2str(i+n_input),'/1'],['Logical',num2str(i+(2*n_input)),'/1'], 'autorouting', 'on');
     add_line(blk, ['posedge',num2str(i),'/1'],['Logical',num2str(i+(2*n_input)),'/2'], 'autorouting', 'on');
     
     
      add_line(blk, ['fstop_sel',num2str(i),'/1'],['Relational_sel',num2str(i),'/1'], 'autorouting', 'on');
      add_line(blk, ['fft_fs/1'],['Relational_sel',num2str(i),'/2'], 'autorouting', 'on');
      add_line(blk, ['Relational_sel',num2str(i),'/1'],['fstop_mux',num2str(i),'/1'], 'autorouting', 'on');
      add_line(blk, ['Delay',num2str(i),'/1'],['fstop_mux',num2str(i),'/2'], 'autorouting', 'on');
      add_line(blk, ['Logical',num2str(i+(2*n_input)),'/1'],['fstop_mux',num2str(i),'/3'], 'autorouting', 'on');
      add_line(blk, ['fstop_mux',num2str(i),'/1'],['Fringe_Theta_Cnt',num2str(i),'/3'], 'autorouting', 'on');
 
 
     add_line(blk,['Fract_Theta_Mult',num2str(i),'/1'],['Fract_Fringe_Adder',num2str(i),'/1'], 'autorouting', 'on');
     add_line(blk,['Fringe_Theta_Cnt',num2str(i),'/1'],['Delay',num2str(i+(2*n_input)),'/1'], 'autorouting', 'on');
    
     add_line(blk,['Delay',num2str(i+(2*n_input)),'/1'],['Fract_Fringe_Adder',num2str(i),'/2'], 'autorouting', 'on');
 
     add_line(blk,['Fract_Fringe_Adder',num2str(i),'/1'],['SineCosine',num2str(i),'/1'], 'autorouting', 'on');
     
     
     add_line(blk,['pol',num2str(i-1),'_in/1'],['Input_Del',num2str(i),'/1'], 'autorouting', 'on');
     add_line(blk,['Input_Del',num2str(i),'/1'], ['c_to_ri',num2str(i),'/1'],'autorouting', 'on');
 
     add_line(blk,['c_to_ri',num2str(i),'/1'],['cmult',num2str(i),'/1'],'autorouting', 'on');
     add_line(blk,['c_to_ri',num2str(i),'/2'],['cmult',num2str(i),'/2'],'autorouting', 'on');
     add_line(blk,['SineCosine',num2str(i),'/2'],['cmult',num2str(i),'/3'],'autorouting', 'on');
     add_line(blk,['SineCosine',num2str(i),'/1'],['cmult',num2str(i),'/4'],'autorouting', 'on');
 
    
     add_line(blk,['cmult',num2str(i),'/1'],['Convert',num2str((i*3)-1),'/1'],'autorouting', 'on');
     add_line(blk,['cmult',num2str(i),'/2'],['Convert',num2str(i*3),'/1'],'autorouting', 'on');
     
     add_line(blk,['Convert',num2str(i*3-1),'/1'],['ri_to_c',num2str(i),'/1'],'autorouting', 'on');
     add_line(blk,['Convert',num2str(i*3),'/1'],['ri_to_c',num2str(i),'/2'],'autorouting', 'on');
     
     add_line(blk,['ri_to_c',num2str(i),'/1'],['out',num2str(i-1),'/1'],'autorouting', 'on');
 
end
 
%    
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
 
clean_blocks(blk);
 
% fmtstr = sprintf('Min Delay=%d',(n_inputs_bits + bram_latency+1));
% Printing at the bottom of the block fmtstr = sprintf('Min
% Delay=%d',(n_inputs_bits + bram_latency+1); %
%set_param(blk, 'AttributesFormatString', fmtstr);
 
% Save all the variables just like global variables in C
 save_state(blk, 'defaults', defaults, varargin{:});
 
