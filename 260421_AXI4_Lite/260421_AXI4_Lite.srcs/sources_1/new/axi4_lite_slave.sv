`timescale 1ns / 1ps

module axi4_lite_slave (
    // Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // AW channel
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // W channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // B channel
    output logic [ 1:0] BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    // AR channel
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // R channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP
);

    logic aw_done, w_done;
    //assign aw_done = AWVALID & AWREADY;
    //assign w_done  = WVALID & WREADY;

    logic [31:0] slv_reg0;
    logic [31:0] slv_reg1;
    logic [31:0] slv_reg2;
    logic [31:0] slv_reg3;

    logic slv_reg_write;

    logic [31:0] rdata_out;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
        end else begin
            if (BVALID & BREADY) begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
            end else begin
                if (AWVALID & AWREADY) aw_done <= 1'b1;
                if (WVALID & WREADY) w_done <= 1'b1;
            end
        end
    end

    /**************** WRITE TRANSACTION ****************/

    // AW channel
    typedef enum {
        AW_IDLE,
        AW_READY
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state <= AW_IDLE;
        end else begin
            aw_state <= aw_state_next;
        end
    end

    always_comb begin
        aw_state_next = aw_state;
        AWREADY = 0;
        case (aw_state)
            AW_IDLE: begin
                AWREADY = 0;
                if (AWVALID) begin
                    aw_state_next = AW_READY;
                end
            end

            AW_READY: begin
                AWREADY = 1;
                if (AWVALID) begin
                    aw_state_next = AW_IDLE;
                end
            end
        endcase
    end

    // W channel
    typedef enum {
        W_IDLE,
        W_READY
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state <= W_IDLE;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state;
        WREADY = 0;
        case (w_state)
            W_IDLE: begin
                WREADY = 0;
                if (WVALID) begin
                    w_state_next = W_READY;
                end
            end

            W_READY: begin
                WREADY = 1;
                if (WVALID) begin
                    w_state_next = W_IDLE;
                end
            end
        endcase
    end

    // B channel
    typedef enum {
        B_IDLE,
        B_VALID
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state;
        BVALID = 0;
        BRESP = 2'b00;
        case (b_state)
            B_IDLE: begin
                BVALID = 0;
                if (aw_done & w_done) begin
                    b_state_next = B_VALID;
                end
            end

            B_VALID: begin
                BVALID = 1;
                BRESP  = 2'b00;
                if (BREADY) begin
                    b_state_next = B_IDLE;
                end
            end
        endcase
    end

    /**************** READ TRANSACTION ****************/

    // AR Channel transfer
    typedef enum {
        AR_IDLE,
        AR_READY
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state <= AR_IDLE;
        end else begin
            ar_state <= ar_state_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ARREADY       = 1'b0;

        case (ar_state)
            AR_IDLE: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next = AR_READY;
                end
            end

            AR_READY: begin
                ARREADY = 1'b1;
                if (ARVALID) begin
                    ar_state_next = AR_IDLE;
                end
            end
        endcase
    end

    // R Channel transfer
    typedef enum {
        R_IDLE,
        R_VALID
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        RVALID       = 1'b0;
        RRESP        = 2'b00;
        RDATA        = 32'h0;

        case (r_state)
            R_IDLE: begin
                RVALID = 1'b0;
                if (ARVALID & ARREADY) begin
                    r_state_next = R_VALID;
                end
            end

            R_VALID: begin
                RVALID = 1'b1;
                RDATA  = rdata_out;
                RRESP  = 2'b00;
                if (RREADY) begin
                    r_state_next = R_IDLE;
                end
            end
        endcase
    end

    /**************** REGISTER LOGIC (데이터 창고) ****************/

    assign slv_reg_write = aw_done & w_done & (b_state == B_IDLE);

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            slv_reg0 <= 32'h0;
            slv_reg1 <= 32'h0;
            slv_reg2 <= 32'h0;
            slv_reg3 <= 32'h0;
        end else begin
            if (slv_reg_write) begin
                case (AWADDR[3:2])
                    2'h0: slv_reg0 <= WDATA;
                    2'h1: slv_reg1 <= WDATA;
                    2'h2: slv_reg2 <= WDATA;
                    2'h3: slv_reg3 <= WDATA;
                endcase
            end
        end
    end

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            rdata_out <= 32'h0;
        end else begin
            if (ARVALID & ARREADY) begin
                case (ARADDR[3:2])
                    2'h0: rdata_out <= slv_reg0;
                    2'h1: rdata_out <= slv_reg1;
                    2'h2: rdata_out <= slv_reg2;
                    2'h3: rdata_out <= slv_reg3;
                endcase
            end
        end
    end

endmodule
