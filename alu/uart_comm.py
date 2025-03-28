import serial
import struct

SERIAL_PORT = "/dev/ttyUSB1"
BAUD_RATE = 115200

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

    opcode = "EC"
    echo_message = "hi"
    A = int()
    B = int()

    if opcode == "EC":
        packet = construct_packet(0xec, echo_data=echo_message)
    else:
        packet = construct_packet(opcode, A, B)

    ser.write(packet)

    formatted_packet = "".join(f"{b:02x}" for b in packet)
    # print("Packet sent:", formatted_packet)

    response = ser.read(256)
    if response:
        ascii_string = bytes.fromhex(response.hex().lstrip("0")[2:]).decode('utf-8')
        print("Opcode: ", opcode, "; Output: ", ascii_string)
    ser.close()


if __name__ == "__main__":
    main()