// NXP_GPIO.cs - NXP RGPIO peripheral model for Renode
// Implements the 6-register NXP GPIO layout:
//   0x00 PDOR - Port Data Output Register       (RW)
//   0x04 PSOR - Port Set Output Register        (WO - sets bits in PDOR)
//   0x08 PCOR - Port Clear Output Register      (WO - clears bits in PDOR)
//   0x0C PTOR - Port Toggle Output Register     (WO - toggles bits in PDOR)
//   0x10 PDIR - Port Data Input Register        (RO - reflects pin state)
//   0x14 PDDR - Port Data Direction Register    (RW)

using Antmicro.Renode.Core;
using Antmicro.Renode.Core.Structure.Registers;
using Antmicro.Renode.Peripherals.Bus;
using Antmicro.Renode.Peripherals.GPIOPort;
using Antmicro.Renode.Logging;

namespace Antmicro.Renode.Peripherals.GPIOPort
{
    public class NXP_GPIO : BaseGPIOPort, IDoubleWordPeripheral, IKnownSize
    {
        public NXP_GPIO(IMachine machine) : base(machine, NumberOfPins)
        {
            registers = new DoubleWordRegisterCollection(this);
            DefineRegisters();
            Reset();
        }

        public uint ReadDoubleWord(long offset)
        {
            return registers.Read(offset);
        }

        public void WriteDoubleWord(long offset, uint value)
        {
            registers.Write(offset, value);
        }

        public override void Reset()
        {
            base.Reset();
            registers.Reset();
            pdor = 0;
            pddr = 0;
        }

        public long Size => 0x18;

        private void DefineRegisters()
        {
            // PDOR - direct read/write of output latch
            registers.DefineRegister((long)Registers.PDOR)
                .WithValueField(0, 32,
                    writeCallback: (_, val) =>
                    {
                        pdor = (uint)val;
                        UpdatePins();
                    },
                    valueProviderCallback: _ => pdor,
                    name: "PDOR");

            // PSOR - write 1 to set corresponding PDOR bit; reads as 0
            registers.DefineRegister((long)Registers.PSOR)
                .WithValueField(0, 32, FieldMode.Write,
                    writeCallback: (_, val) =>
                    {
                        pdor |= (uint)val;
                        UpdatePins();
                    },
                    name: "PSOR");

            // PCOR - write 1 to clear corresponding PDOR bit; reads as 0
            registers.DefineRegister((long)Registers.PCOR)
                .WithValueField(0, 32, FieldMode.Write,
                    writeCallback: (_, val) =>
                    {
                        pdor &= ~(uint)val;
                        UpdatePins();
                    },
                    name: "PCOR");

            // PTOR - write 1 to toggle corresponding PDOR bit; reads as 0
            registers.DefineRegister((long)Registers.PTOR)
                .WithValueField(0, 32, FieldMode.Write,
                    writeCallback: (_, val) =>
                    {
                        pdor ^= (uint)val;
                        UpdatePins();
                    },
                    name: "PTOR");

            // PDIR - reflects actual input pin state (RO)
            registers.DefineRegister((long)Registers.PDIR)
                .WithValueField(0, 32, FieldMode.Read,
                    valueProviderCallback: _ => GetPinState(),
                    name: "PDIR");

            // PDDR - 0=input, 1=output (RW)
            registers.DefineRegister((long)Registers.PDDR)
                .WithValueField(0, 32,
                    writeCallback: (_, val) => pddr = (uint)val,
                    valueProviderCallback: _ => pddr,
                    name: "PDDR");
        }

        private void UpdatePins()
        {
            // Drive output pins according to PDOR and PDDR
            for(int i = 0; i < NumberOfPins; i++)
            {
                if((pddr & (1u << i)) != 0)  // pin configured as output
                {
                    Connections[i].Set((pdor & (1u << i)) != 0);
                }
            }
        }

        private uint GetPinState()
        {
            // For input pins, reflect external State[]; for output pins, reflect PDOR
            uint pdir = 0;
            for(int i = 0; i < NumberOfPins; i++)
            {
                if((pddr & (1u << i)) != 0)
                    pdir |= (pdor & (1u << i));   // output: read back PDOR
                else if(State[i])
                    pdir |= (1u << i);              // input: read actual pin state
            }
            return pdir;
        }

        private uint pdor;
        private uint pddr;
        private readonly DoubleWordRegisterCollection registers;

        private const int NumberOfPins = 32;

        private enum Registers : long
        {
            PDOR = 0x00,
            PSOR = 0x04,
            PCOR = 0x08,
            PTOR = 0x0C,
            PDIR = 0x10,
            PDDR = 0x14,
        }
    }
}