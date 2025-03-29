# import serial

# # FPGA UART settings
# PORT = "/dev/ttyUSB1"
# BAUDRATE = 115200
# ECHO_OPCODE = 0xEC
# ADD_OPCODE  = 0xAD
# MUL_OPCODE  = 0xFF
# DIV_OPCODE  = 0xDE

# def create_packet(opcode, *data):
#     """Creates a structured packet for UART communication."""
#     if opcode == ECHO_OPCODE:
#         length = len(data) + 4  # Opcode + Reserved + Length (2 bytes) + Data
#         packet = bytearray([opcode, 0x00, length & 0xFF, (length >> 8) & 0xFF]) + bytearray(data)
#     else:
#         # Convert numbers into single bytes (if within 8-bit range)
#         data_bytes = bytearray(data)
#         length = len(data_bytes) + 4  # Opcode + Reserved + Length (2 bytes) + Data
#         packet = bytearray([opcode, 0x00, length & 0xFF, (length >> 8) & 0xFF]) + data_bytes
#     return packet

# def create_echo_packet(opcode, data):
#     length = len(data) + 4
#     packet = bytearray([opcode, 0x00, length & 0xFF, (length >> 8) & 0xFF]) + data
#     return packet

# def echo(message):
#     """Sends an echo message to the FPGA and prints the raw response."""
#     data = message.encode('utf-8')
#     packet = create_echo_packet(ECHO_OPCODE, data)

#     with serial.Serial(PORT, BAUDRATE, timeout=2) as ser:
#         ser.write(packet)  # Send the packet
#         response = ser.read()  # Read response (adjust buffer size if needed)

#     print("Raw Response:", response)  # Print the raw response
#     try:
#         print("Decoded Response:", response.decode('utf-8'))
#     except UnicodeDecodeError:
#         print("Response contains non-UTF-8 bytes:", response)

# def test_echo():
#     with serial.Serial(PORT, BAUDRATE, timeout=2) as ser:
#         ser.write(b'\xEC\x00\x05\x00Hello')  # Example echo command
#         response = ser.read(10)  # Read expected bytes
#         print("Raw Echo Response:", response.hex())

# def div32(A, B):
#     """Sends a division operation to the FPGA with correctly formatted bytes."""
#     if B == 0:
#         raise ValueError("Cannot divide by zero!")

#     packet = create_packet(DIV_OPCODE, A, B)
#     print("Sending Packet:", " ".join(f"{b:02x}" for b in packet))  # Print formatted hex output

#     with serial.Serial(PORT, BAUDRATE, timeout=1) as ser:
#         ser.write(packet)  # Send the packet
#         response = ser.read(1024)  # Adjust buffer size based on expected response size

#     if response:
#         print("Raw Response:", " ".join(f"{b:02x}" for b in response))  # Print all bytes received

#         # Ignore the first byte and parse the remaining bytes
#         result_bytes = response[5:]  # Skip the first byte
#         result = int.from_bytes(result_bytes, byteorder='little')  # Assuming little-endian
#         print(f"Division Result: {result}")
#     else:
#         print("No response received.")

# if __name__ == "__main__":
#     test_echo()
#     div32(100, 25)  # Expected result:

import serial
import struct

#UART config
SERIAL_PORT = "/dev/ttyUSB1"
BAUD_RATE = 115200

#Operation codes
OPCODES = {
    "ec": 0xec,  #Echo
    "ac": 0xac,  #Multiplication
    "ad": 0xad,  #Addition
    "d1": 0xd1   #Division
}

def construct_packet(opcode, num1=None, num2=None, echo_data=None):
    """Constructs the packet based on the operation type."""
    reserved = 0x00

    if opcode == 0xec:
        data = echo_data.encode("utf-8")
        length = 4 + len(data)
        msb = (length >> 8) & 0xFF
        lsb = length & 0xFF
        packet = [opcode, reserved, lsb, msb] + list(data)
    else:
        length = 12
        msb = 0x00
        lsb = length & 0xFF
        data0 = list(struct.pack(">I", num1))
        data1 = list(struct.pack(">I", num2))
        packet = [opcode, reserved, lsb, msb] + data0 + data1

    return bytearray(packet)

def main():
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)

    print("Enter operation (ec for echo, ac for multiplication, ad for addition, d1 for division):")
    operation = input().strip().lower()

    if operation not in OPCODES:
        print("Invalid operation.")
        return

    opcode = OPCODES[operation]

    if operation == "ec":
        echo_message = input("Enter the message to echo: ")
        packet = construct_packet(opcode, echo_data=echo_message)
    else:
        num1 = int(input("Enter first number: "))
        num2 = int(input("Enter second number: "))
        packet = construct_packet(opcode, num1, num2)

    ser.write(packet)

    formatted_packet = "".join(f"{b:02x}" for b in packet)
    print("Packet sent:", formatted_packet)

    response = ser.read(256)
    if response:
        formatted_response = response.hex().lstrip("0")


        if not formatted_response:
            formatted_response = "0"

        print("Received (Hex):", formatted_response)


        try:
            decimal_value = int(formatted_response, 16)
            print("Received (Decimal):", decimal_value)
        except ValueError:
            print("Received (Text):", bytes.fromhex(formatted_response).decode(errors="ignore"))

    ser.close()


if __name__ == "__main__":
    main()
