namespace vJoy {
    // Stores number of available buttons to use for SetButton()
    uint numberOfButtons = 0;

    // Current button values are stored in this array
    array<bool> buttonValues = {};
    // Current axis values are stored in this array
    array<int64> axisValues = {16384, 16384, 16384, 0, 0, 0, 0, 0, 0, 0};
    array<int64> defaultAxisValues = {16384, 16384, 16384, 0, 0, 0, 0, 0, 0, 0};
    array<string> axisNames = {"X", "Y", "Z", "RX", "RY", "RZ", "SL0", "SL1", "WHL", "POV"};
    array<Axis> axes = {Axis::X, Axis::Y, Axis::Z, Axis::RX, Axis::RY, Axis::RZ, 
        Axis::SL0, Axis::SL1, Axis::WHL, Axis::POV};

    enum Axis {
        X = 0x30, // X Axis
        Y = 0x31, // Y Axis
        Z = 0x32, // Z Axis
        RX = 0x33, // Rx Axis
        RY = 0x34, // Ry Axis
        RZ = 0x35, // Rz Axis
        SL0 = 0x36, // Slider 0
        SL1 = 0x37, // Slider 1
        WHL = 0x38, // Wheel
        POV = 0x39, // POV
    };

    VJoyLib@ vJoyLib = null;
    // Initialize the vJoy lib and the virtual device
    // This must be called before any other functions
    void Initialize() {
        @vJoyLib = VJoyLib();
        numberOfButtons = vJoyLib.nButtons;
        for(uint i = 0; i < numberOfButtons; i++)
            buttonValues.InsertLast(false);
        Reset();
    }

    // Reset controls and unload the vJoy DLL
    void Destroy(){
        print("Destroying vJoyLib");
        @vJoyLib = null;
    }

    // Set an axis to its desired position
    // Value range [1-32768]
    // Value = 16384 represents centered joystick
    bool SetAxis(Axis axis, int64 value){
        if(value < 0 || value > 0x8000)
            warn("Value for SetAxis must be >= 1 and <= 32768");
        uint axisId = uint(axis);
        uint axisIndex = axisId - 0x30;
        if(axisValues[axisIndex] == value)
            return true;
        axisValues[axisIndex] = value;
        return vJoyLib.SetAxis.CallBool(value, vJoyLib.devId, axisId);
    }

    // Set button down or up
    // button range set by nButtons value returned by dll (probably [0-7] at most [0-127])
    bool SetButton(uint8 button, bool value){
        if(button < 0 || int(button) > vJoyLib.nButtons)
            warn("Button value for SetBtn must be >= 0 and <= " + vJoyLib.nButtons);
        if(buttonValues[button] == value)
            return true;
        buttonValues[button] = value;
        // In TM ui vJoy button 1 is shown as button 0
        button += 1;
        return vJoyLib.SetBtn.CallBool(value, vJoyLib.devId, button);
    }

    // Set a continuous POV Hat Switch to its desired position
    // povHatSwitch range [1-4]
    // value range [-1-35999]
    // Value -1 represents the neutral state of the POV Hat Switch.
    // The range 0-35999 represents its position in 1/100 degree units, where 0 signifies North (or forwards),
    // 9000 signifies East (or right), 18000 signifies South (or backwards), 27000 signifies West (or left) and so forth.
    bool SetContPov(uint8 povHatSwitch, int32 value){
        if(povHatSwitch < 1 || povHatSwitch > 4)
            warn("povHatSwitch for SetDiscPov must be >= 1 and <= 4");
        if(value < -1 || value > 35999)
            warn("value for SetDiscPov must be >= -1 and <= 35999");
        return vJoyLib.SetContPov.CallBool(value, vJoyLib.devId, povHatSwitch);
    }

    // Set a discrete POV Hat Switch to its desired position
    // povHatSwitch range [1-4]
    // value range [-1-3]
    // Value can be set to:
    // 0 North (or Forwards)
    // 1 East (or Right)
    // 2 South (or backwards)
    // 3 West (or left)
    // -1 Neutral (Nothing pressed)
    bool SetDiscPov(uint8 povHatSwitch, int8 value){
        if(povHatSwitch < 1 || povHatSwitch > 4)
            warn("povHatSwitch for SetDiscPov must be >= 1 and <= 4");
        if(value < -1 || value > 3)
            warn("value for SetDiscPov must be >= -1 and <= 3");
        return vJoyLib.SetDiscPov.CallBool(value, vJoyLib.devId, povHatSwitch);
    }

    // Reset all controls to their default values
    bool Reset(){
        for(uint i = 0; i < numberOfButtons; i++)
            SetButton(i, false);
        for(uint i = 0; i < axes.Length; i++)
            SetAxis(axes[i], defaultAxisValues[i]);
        return vJoyLib.ResetVJD.CallBool(vJoyLib.devId);
    }

    // Reset all POV hat switches to their default values
    bool ResetPovs(){
        return vJoyLib.ResetPovs.CallBool(vJoyLib.devId);
    }

    // Call this in a loop to set values in a GUI
    void RenderDebugWindow(){
        UI::Begin("vJoy");

        if(UI::Button("Reset to defaults"))
            Reset();

        UI::Columns(2);

        for(uint i = 0; i < numberOfButtons; i++){
            bool buttonValue = UI::Checkbox("Button " + i, buttonValues[i]);
            SetButton(i, buttonValue);
        }

        UI::NextColumn();

        for(uint i = 0; i < axes.Length; i++){
            if(UI::Button("Reset " + i)){
                SetAxis(axes[i], defaultAxisValues[i]);
            }
            UI::SameLine();
            int axisValue = UI::SliderInt("Axis " + axisNames[i], 
                axisValues[i], 0, 0x8000);
            SetAxis(axes[i], axisValue);
        }

        UI::End();
    }

    void Test(){
        sleep(1000);
        SetAxis(Axis::RX, 8000);
        SetButton(0, true);
        SetDiscPov(1, 3);
        int64 v = 0;
        sleep(500);
        while(true){
            auto result = SetAxis(Axis::X, v);
            print("Set axis x to value: " + v + ", result = " + result);
            v += 50;
            sleep(50);
            if(v > 0x8000)
                break;
        }
        print("Test complete!");
    }
}