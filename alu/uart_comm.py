import serial
import struct

# FPGA UART settings
PORT = "/dev/ttyUSB1"
BAUDRATE = 115200
ECHO_OPCODE = 0xEC
ADD_OPCODE  = 0xAD  
MUL_OPCODE  = 0xFF
DIV_OPCODE  = 0xDE


def create_packet(opcode, *data):
    """Creates a structured packet for UART communication."""
    if opcode == 0xEC:
        length = len(data) + 4  # Opcode + Reserved + Length (2 bytes) + Data
        packet = bytearray([opcode, 0x00, length & 0xFF, (length >> 8) & 0xFF]) + data
    else:
        data_bytes = b''.join(struct.pack('<i', num) for num in data)
        length = len(data_bytes) + 4
        packet = bytearray([opcode, 0x00, length & 0xFF, (length >> 8) & 0xFF]) + data_bytes
    return packet

def create_echo_packet(opcode, data):
    length = len(data) + 4
    packet = bytearray([opcode, 0x00, length & 0xFF, (length >> 8) & 0xFF]) + data
    return packet

def echo(message):
    """Sends an echo message to the FPGA and prints the raw response."""
    data = message.encode('utf-8')
    packet = create_echo_packet(ECHO_OPCODE, data)
    
    with serial.Serial(PORT, BAUDRATE, timeout=1) as ser:
        ser.write(packet)  # Send the packet
        response = ser.read()  # Read response (adjust buffer size if needed)
    
    print("Raw Response:", response)  # Print the raw response
    try:
        print("Decoded Response:", response.decode('utf-8'))
    except UnicodeDecodeError:
        print("Response contains non-UTF-8 bytes:", response)

def add32(*operands):
        packet = create_packet(ADD_OPCODE, *operands)
        # print(packet)
        with serial.Serial(PORT, BAUDRATE, timeout=1) as ser:
            ser.write(packet)  # Send the packet
            response = ser.read(1024)  # Read response (adjust buffer size if needed)
            print("Raw Response:", list(response))
            try:
                print("Decoded Response:", response.decode('utf-8'))
            except UnicodeDecodeError:
                print("Response contains non-UTF-8 bytes:", response)

def mul32(*operands):
        packet = create_packet(MUL_OPCODE, *operands)
        # print(packet)
        with serial.Serial(PORT, BAUDRATE, timeout=1) as ser:
            ser.write(packet)  # Send the packet
            response = ser.read(1024)  # Read response (adjust buffer size if needed)
            print("Raw Response:", list(response))
            try:
                print("Decoded Response:", response.decode('utf-8'))
            except UnicodeDecodeError:
                print("Response contains non-UTF-8 bytes:", response)

def div32(A, B):
        # A / B
        if B == 0:
            raise ValueError("Cannot divide by zero!")
        packet = create_packet(ADD_OPCODE, A, B)
        # print(packet)
        with serial.Serial(PORT, BAUDRATE, timeout=1) as ser:
            ser.write(packet)  # Send the packet
            response = ser.read(1024)  # Read response (adjust buffer size if needed)
            print("Raw Response:", list(response))
            try:
                print("Decoded Response:", response.decode('utf-8'))
            except UnicodeDecodeError:
                print("Response contains non-UTF-8 bytes:", response)

if __name__ == "__main__":
    echo("Wowie")

    add_result = add32(10, 20, 30)
    print("Addition result:", add_result)

    multiply_result = mul32(2, 3, 4)
    print("Multiplication result:", multiply_result)
    
    # Divide integers
    try:
        divide_result = div32(100, 25)
        print("Division result:", divide_result)
    except ValueError as e:
        print(e)