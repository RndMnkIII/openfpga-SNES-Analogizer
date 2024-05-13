//
// User core top-level
//
// Instantiated by the real top-level: apf_top
//

`default_nettype none

module core_top (

    //
    // physical connections
    //

    ///////////////////////////////////////////////////
    // clock inputs 74.25mhz. not phase aligned, so treat these domains as asynchronous

    input wire clk_74a,  // mainclk1
    input wire clk_74b,  // mainclk1 

    ///////////////////////////////////////////////////
    // cartridge interface
    // switches between 3.3v and 5v mechanically
    // output enable for multibit translators controlled by pic32

    // GBA AD[15:8]
    inout  wire [7:0] cart_tran_bank2,
    output wire       cart_tran_bank2_dir,

    // GBA AD[7:0]
    inout  wire [7:0] cart_tran_bank3,
    output wire       cart_tran_bank3_dir,

    // GBA A[23:16]
    inout  wire [7:0] cart_tran_bank1,
    output wire       cart_tran_bank1_dir,

    // GBA [7] PHI#
    // GBA [6] WR#
    // GBA [5] RD#
    // GBA [4] CS1#/CS#
    //     [3:0] unwired
    inout  wire [7:4] cart_tran_bank0,
    output wire       cart_tran_bank0_dir,

    // GBA CS2#/RES#
    inout  wire cart_tran_pin30,
    output wire cart_tran_pin30_dir,
    // when GBC cart is inserted, this signal when low or weak will pull GBC /RES low with a special circuit
    // the goal is that when unconfigured, the FPGA weak pullups won't interfere.
    // thus, if GBC cart is inserted, FPGA must drive this high in order to let the level translators
    // and general IO drive this pin.
    output wire cart_pin30_pwroff_reset,

    // GBA IRQ/DRQ
    inout  wire cart_tran_pin31,
    output wire cart_tran_pin31_dir,

    // infrared
    input  wire port_ir_rx,
    output wire port_ir_tx,
    output wire port_ir_rx_disable,

    // GBA link port
    inout  wire port_tran_si,
    output wire port_tran_si_dir,
    inout  wire port_tran_so,
    output wire port_tran_so_dir,
    inout  wire port_tran_sck,
    output wire port_tran_sck_dir,
    inout  wire port_tran_sd,
    output wire port_tran_sd_dir,

    ///////////////////////////////////////////////////
    // cellular psram 0 and 1, two chips (64mbit x2 dual die per chip)

    output wire [21:16] cram0_a,
    inout  wire [ 15:0] cram0_dq,
    input  wire         cram0_wait,
    output wire         cram0_clk,
    output wire         cram0_adv_n,
    output wire         cram0_cre,
    output wire         cram0_ce0_n,
    output wire         cram0_ce1_n,
    output wire         cram0_oe_n,
    output wire         cram0_we_n,
    output wire         cram0_ub_n,
    output wire         cram0_lb_n,

    output wire [21:16] cram1_a,
    inout  wire [ 15:0] cram1_dq,
    input  wire         cram1_wait,
    output wire         cram1_clk,
    output wire         cram1_adv_n,
    output wire         cram1_cre,
    output wire         cram1_ce0_n,
    output wire         cram1_ce1_n,
    output wire         cram1_oe_n,
    output wire         cram1_we_n,
    output wire         cram1_ub_n,
    output wire         cram1_lb_n,

    ///////////////////////////////////////////////////
    // sdram, 512mbit 16bit

    output wire [12:0] dram_a,
    output wire [ 1:0] dram_ba,
    inout  wire [15:0] dram_dq,
    output wire [ 1:0] dram_dqm,
    output wire        dram_clk,
    output wire        dram_cke,
    output wire        dram_ras_n,
    output wire        dram_cas_n,
    output wire        dram_we_n,

    ///////////////////////////////////////////////////
    // sram, 1mbit 16bit

    output wire [16:0] sram_a,
    inout  wire [15:0] sram_dq,
    output wire        sram_oe_n,
    output wire        sram_we_n,
    output wire        sram_ub_n,
    output wire        sram_lb_n,

    ///////////////////////////////////////////////////
    // vblank driven by dock for sync in a certain mode

    input wire vblank,

    ///////////////////////////////////////////////////
    // i/o to 6515D breakout usb uart

    output wire dbg_tx,
    input  wire dbg_rx,

    ///////////////////////////////////////////////////
    // i/o pads near jtag connector user can solder to

    output wire user1,
    input  wire user2,

    ///////////////////////////////////////////////////
    // RFU internal i2c bus 

    inout  wire aux_sda,
    output wire aux_scl,

    ///////////////////////////////////////////////////
    // RFU, do not use
    output wire vpll_feed,


    //
    // logical connections
    //

    ///////////////////////////////////////////////////
    // video, audio output to scaler
    output wire [23:0] video_rgb,
    output wire        video_rgb_clock,
    output wire        video_rgb_clock_90,
    output wire        video_de,
    output wire        video_skip,
    output wire        video_vs,
    output wire        video_hs,

    output wire audio_mclk,
    input  wire audio_adc,
    output wire audio_dac,
    output wire audio_lrck,

    ///////////////////////////////////////////////////
    // bridge bus connection
    // synchronous to clk_74a
    output wire        bridge_endian_little,
    input  wire [31:0] bridge_addr,
    input  wire        bridge_rd,
    output reg  [31:0] bridge_rd_data,
    input  wire        bridge_wr,
    input  wire [31:0] bridge_wr_data,

    ///////////////////////////////////////////////////
    // controller data
    // 
    // key bitmap:
    //   [0]    dpad_up
    //   [1]    dpad_down
    //   [2]    dpad_left
    //   [3]    dpad_right
    //   [4]    face_a
    //   [5]    face_b
    //   [6]    face_x
    //   [7]    face_y
    //   [8]    trig_l1
    //   [9]    trig_r1
    //   [10]   trig_l2
    //   [11]   trig_r2
    //   [12]   trig_l3
    //   [13]   trig_r3
    //   [14]   face_select
    //   [15]   face_start
    // joy values - unsigned
    //   [ 7: 0] lstick_x
    //   [15: 8] lstick_y
    //   [23:16] rstick_x
    //   [31:24] rstick_y
    // trigger values - unsigned
    //   [ 7: 0] ltrig
    //   [15: 8] rtrig
    //
    input wire [15:0] cont1_key,
    input wire [15:0] cont2_key,
    input wire [15:0] cont3_key,
    input wire [15:0] cont4_key,
    input wire [31:0] cont1_joy,
    input wire [31:0] cont2_joy,
    input wire [31:0] cont3_joy,
    input wire [31:0] cont4_joy,
    input wire [15:0] cont1_trig,
    input wire [15:0] cont2_trig,
    input wire [15:0] cont3_trig,
    input wire [15:0] cont4_trig

);

  // not using the IR port, so turn off both the LED, and
  // disable the receive circuit to save power
  assign port_ir_tx              = 0;
  assign port_ir_rx_disable      = 1;

  // bridge endianness
  assign bridge_endian_little    = 0;

  // cart is unused, so set all level translators accordingly
  // directions are 0:IN, 1:OUT
  // assign cart_tran_bank3         = 8'hzz;
  // assign cart_tran_bank3_dir     = 1'b0;
  // assign cart_tran_bank2         = 8'hzz;
  // assign cart_tran_bank2_dir     = 1'b0;
  // assign cart_tran_bank1         = 8'hzz;
  // assign cart_tran_bank1_dir     = 1'b0;
  // assign cart_tran_bank0         = 4'hf;
  // assign cart_tran_bank0_dir     = 1'b1;
  // assign cart_tran_pin30         = 1'b0;  // reset or cs2, we let the hw control it by itself
  // assign cart_tran_pin30_dir     = 1'bz;
  // assign cart_pin30_pwroff_reset = 1'b0;  // hardware can control this
  // assign cart_tran_pin31         = 1'bz;  // input
  // assign cart_tran_pin31_dir     = 1'b0;  // input

  // link port is input only
  assign port_tran_so            = 1'bz;
  assign port_tran_so_dir        = 1'b0;  // SO is output only
  assign port_tran_si            = 1'bz;
  assign port_tran_si_dir        = 1'b0;  // SI is input only
  assign port_tran_sck           = 1'bz;
  assign port_tran_sck_dir       = 1'b0;  // clock direction can change
  assign port_tran_sd            = 1'bz;
  assign port_tran_sd_dir        = 1'b0;  // SD is input and not used

  // tie off the rest of the pins we are not using
  //   assign cram0_a                 = 'h0;
  //   assign cram0_dq                = {16{1'bZ}};
  //   assign cram0_clk               = 0;
  //   assign cram0_adv_n             = 1;
  //   assign cram0_cre               = 0;
  //   assign cram0_ce0_n             = 1;
  //   assign cram0_ce1_n             = 1;
  //   assign cram0_oe_n              = 1;
  //   assign cram0_we_n              = 1;
  //   assign cram0_ub_n              = 1;
  //   assign cram0_lb_n              = 1;

  //   assign cram1_a                 = 'h0;
  //   assign cram1_dq                = {16{1'bZ}};
  //   assign cram1_clk               = 0;
  //   assign cram1_adv_n             = 1;
  //   assign cram1_cre               = 0;
  //   assign cram1_ce0_n             = 1;
  //   assign cram1_ce1_n             = 1;
  //   assign cram1_oe_n              = 1;
  //   assign cram1_we_n              = 1;
  //   assign cram1_ub_n              = 1;
  //   assign cram1_lb_n              = 1;

  //   assign dram_a                  = 'h0;
  //   assign dram_ba                 = 'h0;
  //   assign dram_dq                 = {16{1'bZ}};
  //   assign dram_dqm                = 'h0;
  //   assign dram_clk                = 'h0;
  //   assign dram_cke                = 'h0;
  //   assign dram_ras_n              = 'h1;
  //   assign dram_cas_n              = 'h1;
  //   assign dram_we_n               = 'h1;

  assign sram_a                  = 'h0;
  assign sram_dq                 = {16{1'bZ}};
  assign sram_oe_n               = 1;
  assign sram_we_n               = 1;
  assign sram_ub_n               = 1;
  assign sram_lb_n               = 1;

  assign dbg_tx                  = 1'bZ;
  assign user1                   = 1'bZ;
  assign aux_scl                 = 1'bZ;
  assign vpll_feed               = 1'bZ;


  // for bridge write data, we just broadcast it to all bus devices
  // for bridge read data, we have to mux it
  // add your own devices here
  always @(*) begin
    casex (bridge_addr)
      default: begin
        bridge_rd_data <= 0;
      end
      32'h10xxxxxx: begin
        // example
        bridge_rd_data
         <= 0;
      end
      32'hF7000000: begin 
        //bridge_rd_data <= {15'h0,analogizer_settings};
        bridge_rd_data <= {18'h0,analogizer_settings};
      end
      32'hF8xxxxxx: begin
        bridge_rd_data <= cmd_bridge_rd_data;
      end
    endcase

    if (bridge_addr[31:28] == 4'h2) begin
      bridge_rd_data <= sd_read_data;
    end
  end

  always @(posedge clk_74a) begin
    if (reset_delay > 0) begin
      reset_delay <= reset_delay - 1;
    end

    if (bridge_wr) begin
      casex (bridge_addr)
        32'h0: begin
          ioctl_download <= bridge_wr_data[0];
        end
        32'h4: begin
          rom_size <= bridge_wr_data[3:0];
        end
        32'h8: begin
          rom_type <= bridge_wr_data[7:0];
        end
        32'hC: begin
          ram_size <= bridge_wr_data[3:0];
        end
        32'h10: begin
          PAL <= bridge_wr_data[0];
        end
        32'h50: begin
          reset_delay <= 32'h100000;
        end
        32'h80: begin
          cpu_turbo_enabled <= bridge_wr_data[0];
        end
        32'h84: begin
          gsu_turbo_enabled <= bridge_wr_data[0];
        end
        32'h100: begin
          multitap_enabled <= bridge_wr_data[0];
        end
        32'h104: begin
          lightgun_enabled <= bridge_wr_data[0];
          lightgun_type    <= bridge_wr_data[1];
          mouse_enabled    <= bridge_wr_data[2];
        end
        32'h00000108: begin
          dpad_aim_speed <= bridge_wr_data[7:0];
        end
        32'h0000010C: begin
          joystick_deadzone <= bridge_wr_data[7:0];
        end
        // 32'h200: begin
        //   use_square_pixels <= bridge_wr_data[0];
        // end
        // 32'h204: begin
        //   blend_enabled <= bridge_wr_data[0];
        // end
        /*[ANALOGIZER_HOOK_BEGIN]*/
        32'h400: begin
          yc_chroma_add <= bridge_wr_data[4:0];
        end
        32'h410: begin
          yc_chroma_mult <= bridge_wr_data[4:0];
        end 
				32'hF7000000: analogizer_settings  <=  bridge_wr_data[13:0];
				/*[ANALOGIZER_HOOK_END]*/
      endcase
    end
  end


  //
  // host/target command handler
  //
  wire reset_n;  // driven by host commands, can be used as core-wide reset
  wire [31:0] cmd_bridge_rd_data;

  // bridge host commands
  // synchronous to clk_74a
  wire status_boot_done = pll_core_locked;
  wire status_setup_done = pll_core_locked;  // rising edge triggers a target command
  wire status_running = reset_n;  // we are running as soon as reset_n goes high

  wire dataslot_requestread;
  wire [15:0] dataslot_requestread_id;
  wire dataslot_requestread_ack = 1;
  wire dataslot_requestread_ok = 1;

  wire dataslot_requestwrite;
  wire [15:0] dataslot_requestwrite_id;
  wire dataslot_requestwrite_ack = 1;
  wire dataslot_requestwrite_ok = 1;

  wire dataslot_allcomplete;

  wire savestate_supported = 0;
  wire [31:0] savestate_addr;
  wire [31:0] savestate_size;
  wire [31:0] savestate_maxloadsize;

  wire savestate_start;
  wire savestate_start_ack;
  wire savestate_start_busy;
  wire savestate_start_ok;
  wire savestate_start_err;

  wire savestate_load;
  wire savestate_load_ack;
  wire savestate_load_busy;
  wire savestate_load_ok;
  wire savestate_load_err;

  wire osnotify_inmenu;

  wire [31:0] rtc_date;
  wire [31:0] rtc_time;

  // bridge target commands
  // synchronous to clk_74a


  // bridge data slot access

  reg [9:0] datatable_addr;
  reg datatable_wren;
  reg [31:0] datatable_data;
  wire [31:0] datatable_q;

  core_bridge_cmd icb (

      .clk    (clk_74a),
      .reset_n(reset_n),

      .bridge_endian_little(bridge_endian_little),
      .bridge_addr         (bridge_addr),
      .bridge_rd           (bridge_rd),
      .bridge_rd_data      (cmd_bridge_rd_data),
      .bridge_wr           (bridge_wr),
      .bridge_wr_data      (bridge_wr_data),

      .status_boot_done (status_boot_done),
      .status_setup_done(status_setup_done),
      .status_running   (status_running),

      .dataslot_requestread    (dataslot_requestread),
      .dataslot_requestread_id (dataslot_requestread_id),
      .dataslot_requestread_ack(dataslot_requestread_ack),
      .dataslot_requestread_ok (dataslot_requestread_ok),

      .dataslot_requestwrite    (dataslot_requestwrite),
      .dataslot_requestwrite_id (dataslot_requestwrite_id),
      .dataslot_requestwrite_ack(dataslot_requestwrite_ack),
      .dataslot_requestwrite_ok (dataslot_requestwrite_ok),

      .dataslot_allcomplete(dataslot_allcomplete),

      .rtc_date(rtc_date),
      .rtc_time(rtc_time),

      .savestate_supported  (savestate_supported),
      .savestate_addr       (savestate_addr),
      .savestate_size       (savestate_size),
      .savestate_maxloadsize(savestate_maxloadsize),

      .savestate_start     (savestate_start),
      .savestate_start_ack (savestate_start_ack),
      .savestate_start_busy(savestate_start_busy),
      .savestate_start_ok  (savestate_start_ok),
      .savestate_start_err (savestate_start_err),

      .savestate_load     (savestate_load),
      .savestate_load_ack (savestate_load_ack),
      .savestate_load_busy(savestate_load_busy),
      .savestate_load_ok  (savestate_load_ok),
      .savestate_load_err (savestate_load_err),

      .osnotify_inmenu(osnotify_inmenu),

      .datatable_addr(datatable_addr),
      .datatable_wren(datatable_wren),
      .datatable_data(datatable_data),
      .datatable_q   (datatable_q)
  );

  reg ioctl_download = 0;
  wire ioctl_wr;
  wire [24:0] ioctl_addr;
  wire [15:0] ioctl_dout;

  reg save_download = 0;
  reg dataslot_allcomplete_prev;

  always @(posedge clk_74a) begin
    dataslot_allcomplete_prev <= dataslot_allcomplete;

    // if (dataslot_requestwrite) ioctl_download <= 1;
    // else if (dataslot_allcomplete) ioctl_download <= 0;

    if (dataslot_requestread || dataslot_requestwrite) save_download <= 1;
    else if (dataslot_allcomplete && ~dataslot_allcomplete_prev) save_download <= 0;
  end

  reg [7:0] rom_type;
  reg [3:0] rom_size;
  reg [3:0] ram_size;
  reg PAL;

  wire save_download_s;

  synch_3 save_s (
      save_download,
      save_download_s,
      clk_sys_21_48
  );

  data_loader #(
      .ADDRESS_MASK_UPPER_4(4'h1),
      .ADDRESS_SIZE(25),
      .WRITE_MEM_CLOCK_DELAY(7),
      .OUTPUT_WORD_SIZE(2)
  ) data_loader (
      .clk_74a(clk_74a),
      .clk_memory(clk_sys_21_48),

      .bridge_wr(bridge_wr),
      .bridge_endian_little(bridge_endian_little),
      .bridge_addr(bridge_addr),
      .bridge_wr_data(bridge_wr_data),

      .write_en  (ioctl_wr),
      .write_addr(ioctl_addr),
      .write_data(ioctl_dout)
  );

  data_loader #(
      .ADDRESS_MASK_UPPER_4(4'h2),
      .ADDRESS_SIZE(17),
      .WRITE_MEM_CLOCK_DELAY(7),
      .OUTPUT_WORD_SIZE(2)
  ) save_data_loader (
      .clk_74a(clk_74a),
      .clk_memory(clk_sys_21_48),

      .bridge_wr(bridge_wr),
      .bridge_endian_little(bridge_endian_little),
      .bridge_addr(bridge_addr),
      .bridge_wr_data(bridge_wr_data),

      .write_en  (sd_wr),
      .write_addr(sd_buff_addr_in),
      .write_data(sd_buff_dout)
  );

  wire [31:0] sd_read_data;

  wire sd_rd;
  wire sd_wr;

  wire [16:0] sd_buff_addr_in;
  wire [16:0] sd_buff_addr_out;

  // Lowest bit is for byte addressing
  wire [15:0] sd_buff_addr = sd_wr ? sd_buff_addr_in[16:1] : sd_buff_addr_out[16:1];

  wire [15:0] sd_buff_din;
  wire [15:0] sd_buff_dout;

  data_unloader #(
      .ADDRESS_MASK_UPPER_4(4'h2),
      .ADDRESS_SIZE(17),
      .READ_MEM_CLOCK_DELAY(7),
      .INPUT_WORD_SIZE(2)
  ) data_unloader (
      .clk_74a(clk_74a),
      .clk_memory(clk_sys_21_48),

      .bridge_rd(bridge_rd),
      .bridge_endian_little(bridge_endian_little),
      .bridge_addr(bridge_addr),
      .bridge_rd_data(sd_read_data),

      .read_en  (sd_rd),
      .read_addr(sd_buff_addr_out),
      .read_data(sd_buff_din)
  );

  always @(posedge clk_74a or negedge pll_core_locked) begin
    if (~pll_core_locked) begin
      datatable_addr <= 0;
      datatable_data <= 0;
      datatable_wren <= 0;
    end else begin
      // Write sram size half of the time
      datatable_wren <= 1;
      // sram_size is the size of the config value in the ROM. Convert to actual size
      datatable_data <= sram_size ? 32'd1024 << sram_size : 32'h0;
      // Data slot index 1, not id 1
      datatable_addr <= 1 * 2 + 1;
    end
  end

  wire [15:0] audio_l;
  wire [15:0] audio_r;

  wire [3:0] sram_size;

  wire [15:0] cont1_key_s;
  wire [15:0] cont2_key_s;
  wire [15:0] cont3_key_s;
  wire [15:0] cont4_key_s;
  wire [31:0] cont1_joy_s;

  wire [15:0] cont1_joy_x = cont1_joy_s[7:0];
  wire [15:0] cont1_joy_y = cont1_joy_s[15:8];
  wire [15:0] cont1_joy_dx = cont1_joy_x[7] ? cont1_joy_x[6:0] : 8'd128 - cont1_joy_x[6:0];
  wire [15:0] cont1_joy_dy = cont1_joy_y[7] ? cont1_joy_y[6:0] : 8'd128 - cont1_joy_y[6:0];
  wire [16:0] cont1_joy_total = cont1_joy_dx + cont1_joy_dy;
  wire [15:0] cont1_joy_x_calibrated = cont1_joy_total > joystick_deadzone ? cont1_joy_x : 8'd128;
  wire [15:0] cont1_joy_y_calibrated = cont1_joy_total > joystick_deadzone ? cont1_joy_y : 8'd128;

  synch_3 #(
      .WIDTH(16)
  ) cont1_s (
      cont1_key,
      cont1_key_s,
      clk_sys_21_48
  );

  synch_3 #(
      .WIDTH(16)
  ) cont2_s (
      cont2_key,
      cont2_key_s,
      clk_sys_21_48
  );

  synch_3 #(
      .WIDTH(16)
  ) cont3_s (
      cont3_key,
      cont3_key_s,
      clk_sys_21_48
  );

  synch_3 #(
      .WIDTH(16)
  ) cont4_s (
      cont4_key,
      cont4_key_s,
      clk_sys_21_48
  );

  synch_3 #(
      .WIDTH(32)
  ) joy1_s (
      cont1_joy,
      cont1_joy_s,
      clk_sys_21_48
  );

  // Settings
  reg [31:0] reset_delay = 0;
  wire reset_button = reset_delay > 0;

  reg cpu_turbo_enabled = 0;
  reg gsu_turbo_enabled = 0;

  reg multitap_enabled = 0;
  reg lightgun_enabled = 0;
  reg lightgun_type = 0;
  reg [7:0] dpad_aim_speed = 0;
  reg [7:0] joystick_deadzone;
  reg mouse_enabled;

  reg use_square_pixels = 0;
  reg blend_enabled = 0;

  // Settings sync
  wire reset_button_s;

  wire cpu_turbo_enabled_s;
  wire gsu_turbo_enabled_s;

  wire multitap_enabled_s;
  wire lightgun_enabled_s;
  wire lightgun_type_s;
  wire [7:0] dpad_aim_speed_s;
  wire [7:0] joystick_deadzone_s;
  wire mouse_enabled_s;

  wire use_square_pixels_s;
  wire blend_enabled_s;

  synch_3 #(
      .WIDTH(25)
  ) settings_s (
      {
        reset_button,
        cpu_turbo_enabled,
        gsu_turbo_enabled,
        multitap_enabled,
        lightgun_enabled,
        lightgun_type,
        dpad_aim_speed,
        joystick_deadzone,
        mouse_enabled,
        use_square_pixels,
        blend_enabled
      },
      {
        reset_button_s,
        cpu_turbo_enabled_s,
        gsu_turbo_enabled_s,
        multitap_enabled_s,
        lightgun_enabled_s,
        lightgun_type_s,
        dpad_aim_speed_s,
        joystick_deadzone_s,
        mouse_enabled_s,
        use_square_pixels_s,
        blend_enabled_s
      },
      clk_sys_21_48
  );

  reg new_rtc = 0;
  reg [31:0] prev_time = 0;

  always @(posedge clk_74a) begin
    if (rtc_time != prev_time) begin
      prev_time <= rtc_time;
      new_rtc   <= ~new_rtc;
    end
  end

  wire [64:0] rtc = {
    new_rtc,
    8'b0,  // Empty
    8'b1,  // Week day (not supported)
    rtc_date[23:16],  // Year (lower byte)
    rtc_date[15:8],  // Month
    rtc_date[7:0],  // Day
    rtc_time[23:16],  // Hour
    rtc_time[15:8],  // Minute
    rtc_time[7:0]  // Second
  };
/*[ANALOGIZER_HOOK_BEGIN]*/
synch_3 #(
  .WIDTH(8)
) yc_s (
    {
      yc_chroma_add,
      yc_chroma_mult
    },
    {
      yc_chroma_add_s,
      yc_chroma_mult_s
    },
    clk_sys_21_48
);

//*** Analogizer Interface V1.2 ***
//Pocket Menu settings
reg [13:0] analogizer_settings = 0;
wire [13:0] analogizer_settings_s;
reg [4:0] yc_chroma_add;
reg [4:0] yc_chroma_mult;
wire [4:0] yc_chroma_add_s;
wire [4:0] yc_chroma_mult_s;

synch_3 #(.WIDTH(32)) sync_analogizer(analogizer_settings, analogizer_settings_s, clk_sys_21_48);

  always @(*) begin
    snac_game_cont_type   = analogizer_settings_s[4:0];
    snac_cont_assignment  = analogizer_settings_s[9:6];
    analogizer_video_type = analogizer_settings_s[13:10];
  end

wire clk_vid = video_rgb_clock; //video_rgb_clock; //Fixed one bit shift error on RGB channels.
wire SYNC = ~^{video_hs_snes, video_vs_snes};
wire  ANALOGIZER_DE = ~(h_blank || v_blank);
  //create aditional switch to blank Pocket screen.
  wire [23:0] video_rgb_pocket;
  assign video_rgb_pocket = (analogizer_video_type[3]) ? 24'h000000: video_rgb_snes;

reg analogizer_ena;
reg [3:0] analogizer_video_type;
reg [4:0] snac_game_cont_type /* synthesis keep */;
reg [3:0] snac_cont_assignment /* synthesis keep */;


//switch between Analogizer SNAC and Pocket Controls for P1-P4 (P3,P4 when uses PCEngine Multitap)
  wire [15:0] p1_btn, p2_btn, p3_btn, p4_btn;
  reg [15:0] p1_controls, p2_controls, p3_controls, p4_controls;
  reg [15:0] p1_stick_x, p1_stick_y;

  always @(posedge clk_sys_21_48) begin
    if(snac_game_cont_type == 5'h0) begin //SNAC is disabled
                  p1_controls <= cont1_key_s;
                  p1_stick_x  <= cont1_joy_x_calibrated;
                  p1_stick_y  <= cont1_joy_y_calibrated;
                  p2_controls <= cont2_key_s;
                  p3_controls <= cont3_key_s;
                  p4_controls <= cont4_key_s;
    end
    else begin
      case(snac_cont_assignment)
      4'h0:    begin 
                  p1_controls <= p1_btn;
                  p1_stick_x  <= 16'd0;
                  p1_stick_y  <= 16'd0;
                  p2_controls <= cont2_key_s;
                  p3_controls <= cont3_key_s;
                  p4_controls <= cont4_key_s;
                end
      4'h1:    begin 
                  p1_controls <= cont1_key_s;
                  p1_stick_x  <= cont1_joy_x_calibrated;
                  p1_stick_y  <= cont1_joy_y_calibrated;
                  p2_controls <= p1_btn;
                  p3_controls <= cont3_key_s;
                  p4_controls <= cont4_key_s;
                end
      4'h2:    begin
                  p1_controls <= p1_btn;
                  p1_stick_x  <= 16'd0;
                  p1_stick_y  <= 16'd0;
                  p2_controls <= p2_btn;
                  p3_controls <= cont3_key_s;
                  p4_controls <= cont4_key_s;
                end
      4'h3:    begin
                  p1_controls <= p2_btn;
                  p1_stick_x  <= 16'd0;
                  p1_stick_y  <= 16'd0;
                  p2_controls <= p1_btn;
                  p3_controls <= cont3_key_s;
                  p4_controls <= cont4_key_s;
                end
      4'h4:    begin
                  p1_controls <= p1_btn;
                  p1_stick_x  <= 16'd0;
                  p1_stick_y  <= 16'd0;
                  p2_controls <= p2_btn;
                  p3_controls <= p3_btn;
                  p4_controls <= p4_btn;
                end
      4'h5:    begin
                  p1_controls <= p4_btn;
                  p1_stick_x  <= 16'd0;
                  p1_stick_y  <= 16'd0;
                  p2_controls <= p3_btn;
                  p3_controls <= p2_btn;
                  p4_controls <= p1_btn;
                end
      4'h6:    begin
                  p1_controls <= cont1_key_s;
                  p2_controls <= cont2_key_s;
                  p3_controls <= p1_btn;
                  p4_controls <= p2_btn;
                end
      default: begin
                  p1_controls <= cont1_key_s;
                  p1_stick_x  <= cont1_joy_x_calibrated;
                  p1_stick_y  <= cont1_joy_y_calibrated;
                  p2_controls <= cont2_key_s;
                  p3_controls <= cont3_key_s;
                  p4_controls <= cont4_key_s;
                end
      endcase
    end
  end


// Video Y/C Encoder settings
// Follows the Mike Simone Y/C encoder settings:
// https://github.com/MikeS11/MiSTerFPGA_YC_Encoder
// SET PAL and NTSC TIMING and pass through status bits. ** YC must be enabled in the qsf file **
wire [39:0] CHROMA_PHASE_INC;
wire [26:0] COLORBURST_RANGE;
wire [4:0] CHROMA_ADD;
wire [4:0] CHROMA_MULT;
wire PALFLAG;

parameter NTSC_REF = 3.579545;   
parameter PAL_REF = 4.43361875;
// Colorburst Lenth Calculation to send to Y/C Module, based on the CLK_VIDEO of the core
localparam [6:0] COLORBURST_START = (3.7 * (CLK_VIDEO_NTSC/NTSC_REF));
localparam [9:0] COLORBURST_NTSC_END = (9 * (CLK_VIDEO_NTSC/NTSC_REF)) + COLORBURST_START;
localparam [9:0] COLORBURST_PAL_END = (10 * (CLK_VIDEO_PAL/PAL_REF)) + COLORBURST_START;

// Parameters to be modifed
//parameter CLK_VIDEO_NTSC = 42.954545; // Must be filled E.g XX.X Hz - CLK_VIDEO
//parameter CLK_VIDEO_PAL  = 42.562740; // Must be filled E.g XX.X Hz - CLK_VIDEO
//NTSC 21.4772725
parameter CLK_VIDEO_NTSC = 21.4772725;
//PAL 21.28137
parameter CLK_VIDEO_PAL  = 21.28137;
//PAL CLOCK FREQUENCY SHOULD BE 42.56274
//localparam [39:0] NTSC_PHASE_INC = 40'd91625968981; //d91_625_958_315; //d91_625_968_981; // ((NTSC_REF**2^40) / CLK_VIDEO_NTSC) - SNES Example;
localparam [39:0] NTSC_PHASE_INC = 40'd183251916632; //for CLK_VIDEO_NTSC = 21.4772725
//localparam [39:0] PAL_PHASE_INC = 40'd114532461227; // ((PAL_REF*2^40) / CLK_VIDEO_PAL)- SNES Example;
localparam [39:0] PAL_PHASE_INC =  40'd229064922453; //for CLK_VIDEO_PAL  = 21.28137;

assign CHROMA_PHASE_INC = ((analogizer_video_type == 4'h4)|| (analogizer_video_type == 4'hC)) ? PAL_PHASE_INC : NTSC_PHASE_INC; 
assign PALFLAG = (analogizer_video_type == 4'h4) || (analogizer_video_type == 4'hC); 
assign CHROMA_ADD = yc_chroma_add_s;
assign CHROMA_MULT = yc_chroma_mult_s;
//assign CHROMA_ADD = 5'd0;
//assign CHROMA_MULT = 5'd0;
assign COLORBURST_RANGE = {COLORBURST_START, COLORBURST_NTSC_END, COLORBURST_PAL_END}; // Pass colorburst length

generate
  if (PAL_PLL) begin
    parameter MASTER_CLK_FREQ = 21_281_370;
  end else begin
    parameter MASTER_CLK_FREQ = 21_477_270;
  end
endgenerate

openFPGA_Pocket_Analogizer #(.MASTER_CLK_FREQ(MASTER_CLK_FREQ)) analogizer (
	.i_clk(clk_sys_21_48),
	.i_rst((~pll_core_locked || reset_button_s)), //i_rst is active high
	.i_ena(1'b1),
	//Video interface
	.analog_video_type(analogizer_video_type),
  //.analog_video_type(4'd0),
	.R(video_rgb_snes[23:16]),
	.G(video_rgb_snes[15:8]),
	.B(video_rgb_snes[7:0]),
  .Hblank(h_blank),
  .Vblank(v_blank),
  .BLANKn(ANALOGIZER_DE),
  .Csync(SYNC),
	.Hsync(video_hs_snes), //composite SYNC on HSync.
	.Vsync(video_vs_snes),
	.video_clk(clk_vid),
  //Video Y/C Encoder interface
  .PALFLAG(PALFLAG),
	.MULFLAG(1'b0),
	.CHROMA_ADD(CHROMA_ADD),
	.CHROMA_MULT(CHROMA_MULT),
	.CHROMA_PHASE_INC(CHROMA_PHASE_INC),
	.COLORBURST_RANGE(COLORBURST_RANGE),
  //Video SVGA Scandoubler interface
  .ce_divider(3'd0), //div4
	//SNAC interface
	.conf_AB((snac_game_cont_type >= 5'd16)),              //0 conf. A(default), 1 conf. B (see graph above)
	.game_cont_type(snac_game_cont_type), //0-15 Conf. A, 16-31 Conf. B
	.p1_btn_state(p1_btn),
	.p2_btn_state(p2_btn),  
  .p3_btn_state(p3_btn),
	.p4_btn_state(p4_btn),   
	//Pocket Analogizer IO interface to the Pocket cartridge port
	.cart_tran_bank2(cart_tran_bank2),
	.cart_tran_bank2_dir(cart_tran_bank2_dir),
	.cart_tran_bank3(cart_tran_bank3),
	.cart_tran_bank3_dir(cart_tran_bank3_dir),
	.cart_tran_bank1(cart_tran_bank1),
	.cart_tran_bank1_dir(cart_tran_bank1_dir),
	.cart_tran_bank0(cart_tran_bank0),
	.cart_tran_bank0_dir(cart_tran_bank0_dir),
	.cart_tran_pin30(cart_tran_pin30),
	.cart_tran_pin30_dir(cart_tran_pin30_dir),
	.cart_pin30_pwroff_reset(cart_pin30_pwroff_reset),
	.cart_tran_pin31(cart_tran_pin31),
	.cart_tran_pin31_dir(cart_tran_pin31_dir),
	//debug
	.o_stb()
);
/*[ANALOGIZER_HOOK_END]*/

  MAIN_SNES snes (
      .clk_mem_85_9 (clk_mem_85_9),
      .clk_sys_21_48(clk_sys_21_48),

      .core_reset(~pll_core_locked || reset_button_s),

      .rtc(rtc),

      // Settings
      .cpu_turbo_enabled(cpu_turbo_enabled_s),
      .gsu_turbo_enabled(gsu_turbo_enabled_s),

      .multitap_enabled(multitap_enabled_s),
      .lightgun_enabled(lightgun_enabled_s),
      .lightgun_type(lightgun_type_s),
      .dpad_aim_speed(dpad_aim_speed_s),
      .mouse_enabled(mouse_enabled_s),

      .blend_enabled(blend_enabled_s),

      // Input
      .p1_button_a(p1_controls[4]),
      .p1_button_b(p1_controls[5]),
      .p1_button_x(p1_controls[6]),
      .p1_button_y(p1_controls[7]),
      .p1_button_trig_l(p1_controls[8]),
      .p1_button_trig_r(p1_controls[9]),
      .p1_button_start(p1_controls[15]),
      .p1_button_select(p1_controls[14]),
      .p1_dpad_up(p1_controls[0]),
      .p1_dpad_down(p1_controls[1]),
      .p1_dpad_left(p1_controls[2]),
      .p1_dpad_right(p1_controls[3]),

      .p1_lstick_x(p1_stick_x),
      .p1_lstick_y(p1_stick_y),

      .p2_button_a(p2_controls[4]),
      .p2_button_b(p2_controls[5]),
      .p2_button_x(p2_controls[6]),
      .p2_button_y(p2_controls[7]),
      .p2_button_trig_l(p2_controls[8]),
      .p2_button_trig_r(p2_controls[9]),
      .p2_button_start(p2_controls[15]),
      .p2_button_select(p2_controls[14]),
      .p2_dpad_up(p2_controls[0]),
      .p2_dpad_down(p2_controls[1]),
      .p2_dpad_left(p2_controls[2]),
      .p2_dpad_right(p2_controls[3]),

      .p3_button_a(p3_controls[4]),
      .p3_button_b(p3_controls[5]),
      .p3_button_x(p3_controls[6]),
      .p3_button_y(p3_controls[7]),
      .p3_button_trig_l(p3_controls[8]),
      .p3_button_trig_r(p3_controls[9]),
      .p3_button_start(p3_controls[15]),
      .p3_button_select(p3_controls[14]),
      .p3_dpad_up(p3_controls[0]),
      .p3_dpad_down(p3_controls[1]),
      .p3_dpad_left(p3_controls[2]),
      .p3_dpad_right(p3_controls[3]),

      .p4_button_a(p4_controls[4]),
      .p4_button_b(p4_controls[5]),
      .p4_button_x(p4_controls[6]),
      .p4_button_y(p4_controls[7]),
      .p4_button_trig_l(p4_controls[8]),
      .p4_button_trig_r(p4_controls[9]),
      .p4_button_start(p4_controls[15]),
      .p4_button_select(p4_controls[14]),
      .p4_dpad_up(p4_controls[0]),
      .p4_dpad_down(p4_controls[1]),
      .p4_dpad_left(p4_controls[2]),
      .p4_dpad_right(p4_controls[3]),

      // ROM loading
      .ioctl_download(ioctl_download),
      .ioctl_wr(ioctl_wr),
      .ioctl_addr(ioctl_addr),
      .ioctl_dout(ioctl_dout),

      .rom_type(rom_type),
      .rom_size(rom_size),
      .ram_size(ram_size),
      .PAL(PAL),
      .DIS_SHORTLINE(1'b1), //sNTSC-DeJitter mode Enabled -> 1'b1


      // Save input/output
      .save_download(save_download_s),
      .sd_rd(sd_rd),
      .sd_wr(sd_wr),
      .sd_buff_addr(sd_buff_addr),
      .sd_buff_din(sd_buff_din),
      .sd_buff_dout(sd_buff_dout),

      .sram_size(sram_size),

      // SDRAM
      .dram_a(dram_a),
      .dram_ba(dram_ba),
      .dram_dq(dram_dq),
      .dram_dqm(dram_dqm),
      .dram_clk(dram_clk),
      .dram_cke(dram_cke),
      .dram_ras_n(dram_ras_n),
      .dram_cas_n(dram_cas_n),
      .dram_we_n(dram_we_n),

      // PSRAM
      .cram0_a(cram0_a),
      .cram0_dq(cram0_dq),
      .cram0_wait(cram0_wait),
      .cram0_clk(cram0_clk),
      .cram0_adv_n(cram0_adv_n),
      .cram0_cre(cram0_cre),
      .cram0_ce0_n(cram0_ce0_n),
      .cram0_ce1_n(cram0_ce1_n),
      .cram0_oe_n(cram0_oe_n),
      .cram0_we_n(cram0_we_n),
      .cram0_ub_n(cram0_ub_n),
      .cram0_lb_n(cram0_lb_n),

      .cram1_a(cram1_a),
      .cram1_dq(cram1_dq),
      .cram1_wait(cram1_wait),
      .cram1_clk(cram1_clk),
      .cram1_adv_n(cram1_adv_n),
      .cram1_cre(cram1_cre),
      .cram1_ce0_n(cram1_ce0_n),
      .cram1_ce1_n(cram1_ce1_n),
      .cram1_oe_n(cram1_oe_n),
      .cram1_we_n(cram1_we_n),
      .cram1_ub_n(cram1_ub_n),
      .cram1_lb_n(cram1_lb_n),

      // Video
  //     	.FIELD(FIELD),
	// .INTERLACE(INTERLACE),
	// .HIGH_RES(HIGH_RES),
	// .DOTCLK(DOTCLK_out),
      .hblank (h_blank),
      .vblank (v_blank),
      .hsync  (video_hs_snes),
      .vsync  (video_vs_snes),
      .video_r(video_rgb_snes[23:16]),
      .video_g(video_rgb_snes[15:8]),
      .video_b(video_rgb_snes[7:0]),

      // Audio
      .audio_l(audio_l),
      .audio_r(audio_r)
  );

  // Video

  wire h_blank;
  wire v_blank;
  wire video_hs_snes;
  wire video_vs_snes;
  wire [23:0] video_rgb_snes;

  assign video_rgb_clock = clk_video_5_37;
  assign video_rgb_clock_90 = clk_video_5_37_90deg;
  assign video_rgb = rgb;
  assign video_de = de;

  reg de;
  reg [23:0] rgb;
  wire [7:0] snap_index;
  wire [23:0] rgb_out;
  wire de_out;

  scanline_filler #(
      .SNAP_COUNT (2),
      .SNAP_POINTS('{240, 224}),
      .HSYNC_DELAY(1)
  ) scanline_filler (
      .clk(clk_video_5_37),

      .hsync_in(video_hs_snes),
      .vsync_in(video_vs_snes),

      .vblank_in(v_blank),
      .hblank_in(h_blank),
      .rgb_in(video_rgb_pocket),

      .hsync(video_hs),
      .vsync(video_vs),

      .de (de_out),
      .rgb(rgb_out),

      .snap_index(snap_index)
  );

  reg prev_de;
  reg prev_vs;
  reg [7:0] latched_snap_index;

  always @(posedge clk_video_5_37) begin
    prev_de <= de_out;
    prev_vs <= video_vs;

    de <= 0;

    if (video_vs && ~prev_vs) begin
      latched_snap_index <= snap_index;
    end

    if (~de_out && prev_de) begin
      // Write video slot
      rgb <= {9'b0, ~latched_snap_index[0], use_square_pixels_s, 10'b0, 3'b0};
    end else if (de_out) begin
      de  <= 1;
      rgb <= rgb_out;
    end
  end

  sound_i2s #(
      .CHANNEL_WIDTH(16),
      .SIGNED_INPUT (1)
  ) sound_i2s (
      .clk_74a  (clk_74a),
      .clk_audio(clk_sys_21_48),

      .audio_l(audio_l),
      .audio_r(audio_r),

      .audio_mclk(audio_mclk),
      .audio_lrck(audio_lrck),
      .audio_dac (audio_dac)
  );

  ///////////////////////////////////////////////

  wire clk_mem_85_9;
  wire clk_sys_21_48;
  wire clk_video_5_37;
  wire clk_video_5_37_90deg;

  wire pll_core_locked;

  parameter PAL_PLL = 1'b0;

  generate
    if (PAL_PLL) begin
      mf_pllbase_pal mp1 (
          .refclk(clk_74a),

          .outclk_0(clk_mem_85_9),
          .outclk_1(clk_sys_21_48),
          .outclk_2(clk_video_5_37),
          .outclk_3(clk_video_5_37_90deg),

          .locked(pll_core_locked)
      );
    end else begin
      mf_pllbase mp1 (
          .refclk(clk_74a),

          .outclk_0(clk_mem_85_9),
          .outclk_1(clk_sys_21_48),
          .outclk_2(clk_video_5_37),
          .outclk_3(clk_video_5_37_90deg),

          .locked(pll_core_locked)
      );
    end
  endgenerate

endmodule
