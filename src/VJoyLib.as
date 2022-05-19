class VJoyLib {
    uint devId = 1;
    int nButtons = 0;
    Import::Library@ lib = null;
    
    Import::Function@ AcquireVJD = null;
    Import::Function@ DriverMatch = null;
    Import::Function@ Ffb_h_DevCtrl = null;
    Import::Function@ Ffb_h_DevGain = null;
    Import::Function@ Ffb_h_DeviceID = null;
    Import::Function@ Ffb_h_EBI = null;
    Import::Function@ Ffb_h_Eff_Cond = null;
    Import::Function@ Ffb_h_Eff_Constant = null;
    Import::Function@ Ffb_h_Eff_Envlp = null;
    Import::Function@ Ffb_h_Eff_Period = null;
    Import::Function@ Ffb_h_Eff_Ramp = null;
    Import::Function@ Ffb_h_Eff_Report = null;
    Import::Function@ Ffb_h_EffNew = null;
    Import::Function@ Ffb_h_EffOp = null;
    Import::Function@ Ffb_h_Packet = null;
    Import::Function@ Ffb_h_Type = null;
    Import::Function@ FfbGetEffect = null;
    Import::Function@ FfbRegisterGenCB = null;
    Import::Function@ FfbStart = null;
    Import::Function@ FfbStop = null;
    Import::Function@ GetNumberExistingVJD = null;
    Import::Function@ GetOwnerPid = null;
    Import::Function@ GetVJDAxisExist = null;
    Import::Function@ GetVJDAxisMax = null;
    Import::Function@ GetVJDAxisMin = null;
    Import::Function@ GetVJDButtonNumber = null;
    Import::Function@ GetVJDContPovNumber = null;
    Import::Function@ GetVJDDiscPovNumber = null;
    Import::Function@ GetVJDStatus = null;
    Import::Function@ GetvJoyManufacturerString = null;
    Import::Function@ GetvJoyMaxDevices = null;
    Import::Function@ GetvJoyProductString = null;
    Import::Function@ GetvJoySerialNumberString = null;
    Import::Function@ GetvJoyVersion = null;
    Import::Function@ IsDeviceFfb = null;
    Import::Function@ IsDeviceFfbEffect = null;
    Import::Function@ isVJDExists = null;
    Import::Function@ isVJDOpen = null;
    Import::Function@ RegisterRemovalCB = null;
    Import::Function@ RelinquishVJD = null;
    Import::Function@ ResetAll = null;
    Import::Function@ ResetButtons = null;
    Import::Function@ ResetPovs = null;
    Import::Function@ ResetVJD = null;
    Import::Function@ SetAxis = null;
    Import::Function@ SetBtn = null;
    Import::Function@ SetContPov = null;
    Import::Function@ SetDiscPov = null;
    Import::Function@ UpdateVJD = null;
    Import::Function@ vJoyEnabled = null;
    Import::Function@ vJoyFfbCap = null;

    VJoyLib(){
        print("Initializing VJoy");
        auto libPath = 'lib/vJoyInterface.dll';
        print("lib path: " + libPath);
        @lib = GetZippedLibrary(libPath);
        
        if(!TestVJoy(lib))
            return;

        if(!GetVJoyDevice(lib, devId))
            return;

        bool result = ResetVJD.CallBool(devId);
        print("Reset vJoy device result: " + result);
    }

    ~VJoyLib(){
        print("Resetting and destroying vJoy");
        if(lib !is null){
            ResetAll.Call();
            RelinquishVJD.Call(devId);
        }
        @lib = null;
    }

    Import::Library@ GetZippedLibrary(const string &in relativeDllPath) {
        bool testNonAutomated = false;
        if(testNonAutomated) {
            warn("Testing non automated version");
            return null;
        }
        bool preventCache = false;

        auto parts = relativeDllPath.Split("/");
        string fileName = parts[parts.Length - 1];
        const string baseFolder = IO::FromDataFolder('');
        const string dllFolder = baseFolder + 'lib/';
        const string localDllFile = dllFolder + fileName;

        if(!IO::FolderExists(dllFolder)) {
            IO::CreateFolder(dllFolder);
        }

        if(preventCache || !IO::FileExists(localDllFile)) {
            try {
                IO::FileSource zippedDll(relativeDllPath);
                auto buffer = zippedDll.Read(zippedDll.Size());
                IO::File toItem(localDllFile, IO::FileMode::Write);
                toItem.Write(buffer);
                toItem.Close();
            } catch {
                return null;
            }
        }

        return Import::GetLibrary(localDllFile);
    }
    
    // Check vJoy device
    bool GetVJoyDevice(Import::Library@ lib, int devId){
        bool vjdExist = lib.GetFunction('isVJDExists').CallBool(devId);
        print("VJD is exist? " + vjdExist);
        bool vjdOpen = lib.GetFunction('isVJDOpen').CallBool(devId);
        print("VJD is open? " + vjdOpen);

        int status = lib.GetFunction('GetVJDStatus').CallInt32(devId);
        //0: VJD_STAT_OWN,	// The  vJoy Device is owned by this application.
        //1: VJD_STAT_FREE,	// The  vJoy Device is NOT owned by any application (including this one).
        //2: VJD_STAT_BUSY,	// The  vJoy Device is owned by another application. It cannot be acquired by this application.
        //3: VJD_STAT_MISS,	// The  vJoy Device is missing. It either does not exist or the driver is down.
        //4: VJD_STAT_UNKN	// Unknown
        if(status >= 2){
            warn("Couldn't access vJoy device, status = " + status);
            return false;
        }

        print("vJoy device " + devId + ", status = " + status + ", capabilities:");

        // Check which axes are supported (crash!)
        auto GetVJDAxisExist = lib.GetFunction('GetVJDAxisExist');


        bool axisX = GetVJDAxisExist.CallBool(devId, 0x30); // HID_USAGE_X
        bool axisY = GetVJDAxisExist.CallBool(devId, 0x31); // HID_USAGE_Y
        bool axisZ = GetVJDAxisExist.CallBool(devId, 0x32); // HID_USAGE_Z
        bool axisRX = GetVJDAxisExist.CallBool(devId, 0x33); // HID_USAGE_RX
        bool axisRY = GetVJDAxisExist.CallBool(devId, 0x34); // HID_USAGE_RY
        bool axisRZ = GetVJDAxisExist.CallBool(devId, 0x35); // HID_USAGE_RZ
        bool axisSL0 = GetVJDAxisExist.CallBool(devId, 0x36); // HID_USAGE_SL0
        bool axisSL1 = GetVJDAxisExist.CallBool(devId, 0x37); // HID_USAGE_SL1
        bool axisWHL = GetVJDAxisExist.CallBool(devId, 0x38); // HID_USAGE_WHL
        bool axisPOV = GetVJDAxisExist.CallBool(devId, 0x39); // HID_USAGE_POV
        print("axisX: " + axisX);
        print("axisY: " + axisY);
        print("axisZ: " + axisZ);
        print("axisRX: " + axisRX);
        print("axisRY: " + axisRY);
        print("axisRZ: " + axisRZ);
        print("axisSL0: " + axisSL0);
        print("axisSL1: " + axisSL1);
        print("axisWHL: " + axisWHL);
        print("axisPOV: " + axisPOV);

        // Get the number of buttons supported by this vJoy device
        nButtons = lib.GetFunction('GetVJDButtonNumber').CallInt32(devId);

        print(nButtons + " buttons");

        if(status == 1){
            bool aqcuired = lib.GetFunction('AcquireVJD').CallBool(devId);
            if(!aqcuired){
                warn("Failed to aqcuire vJoy device!");
                return false;
            }
        }
        print("Now owning vJoy device with id: " + devId);

        return true;
    }

    // Check vJoy library
    bool TestVJoy(Import::Library@ lib){
        if(lib is null){
            print("Failed to import lib");
            return false;
        }

        LoadFunctions(lib);
        print("Loaded lib! " + lib.GetPath());

        auto isEnabled = vJoyEnabled.CallBool();

        print("vJoy enabled? " + isEnabled);

        if(isEnabled){
            auto manufacturer = GetvJoyManufacturerString.CallWString();
            auto product = GetvJoyProductString.CallWString();
            auto serialNumber = GetvJoySerialNumberString.CallWString();
            print("Manufacturer = " + manufacturer);
            print("Product = " + product);
            print("SerialNumber = " + serialNumber);
        }

        auto driverMatch = GetvJoySerialNumberString.CallBool();
        print("Driver match? " + driverMatch);

        if(!driverMatch){
            warn("vJoy dll and driver don't match!");
        }

        return isEnabled;
    }

    void LoadFunctions(Import::Library@ lib){
        @AcquireVJD = lib.GetFunction('AcquireVJD');
        @DriverMatch = lib.GetFunction('DriverMatch');
        @Ffb_h_DevCtrl = lib.GetFunction('Ffb_h_DevCtrl');
        @Ffb_h_DevGain = lib.GetFunction('Ffb_h_DevGain');
        @Ffb_h_DeviceID = lib.GetFunction('Ffb_h_DeviceID');
        @Ffb_h_EBI = lib.GetFunction('Ffb_h_EBI');
        @Ffb_h_Eff_Cond = lib.GetFunction('Ffb_h_Eff_Cond');
        @Ffb_h_Eff_Constant = lib.GetFunction('Ffb_h_Eff_Constant');
        @Ffb_h_Eff_Envlp = lib.GetFunction('Ffb_h_Eff_Envlp');
        @Ffb_h_Eff_Period = lib.GetFunction('Ffb_h_Eff_Period');
        @Ffb_h_Eff_Ramp = lib.GetFunction('Ffb_h_Eff_Ramp');
        @Ffb_h_Eff_Report = lib.GetFunction('Ffb_h_Eff_Report');
        @Ffb_h_EffNew = lib.GetFunction('Ffb_h_EffNew');
        @Ffb_h_EffOp = lib.GetFunction('Ffb_h_EffOp');
        @Ffb_h_Packet = lib.GetFunction('Ffb_h_Packet');
        @Ffb_h_Type = lib.GetFunction('Ffb_h_Type');
        @FfbGetEffect = lib.GetFunction('FfbGetEffect');
        @FfbRegisterGenCB = lib.GetFunction('FfbRegisterGenCB');
        @FfbStart = lib.GetFunction('FfbStart');
        @FfbStop = lib.GetFunction('FfbStop');
        @GetNumberExistingVJD = lib.GetFunction('GetNumberExistingVJD');
        @GetOwnerPid = lib.GetFunction('GetOwnerPid');
        @GetVJDAxisExist = lib.GetFunction('GetVJDAxisExist');
        @GetVJDAxisMax = lib.GetFunction('GetVJDAxisMax');
        @GetVJDAxisMin = lib.GetFunction('GetVJDAxisMin');
        @GetVJDButtonNumber = lib.GetFunction('GetVJDButtonNumber');
        @GetVJDContPovNumber = lib.GetFunction('GetVJDContPovNumber');
        @GetVJDDiscPovNumber = lib.GetFunction('GetVJDDiscPovNumber');
        @GetVJDStatus = lib.GetFunction('GetVJDStatus');
        @GetvJoyManufacturerString = lib.GetFunction('GetvJoyManufacturerString');
        @GetvJoyMaxDevices = lib.GetFunction('GetvJoyMaxDevices');
        @GetvJoyProductString = lib.GetFunction('GetvJoyProductString');
        @GetvJoySerialNumberString = lib.GetFunction('GetvJoySerialNumberString');
        @GetvJoyVersion = lib.GetFunction('GetvJoyVersion');
        @IsDeviceFfb = lib.GetFunction('IsDeviceFfb');
        @IsDeviceFfbEffect = lib.GetFunction('IsDeviceFfbEffect');
        @isVJDExists = lib.GetFunction('isVJDExists');
        @isVJDOpen = lib.GetFunction('isVJDOpen');
        @RegisterRemovalCB = lib.GetFunction('RegisterRemovalCB');
        @RelinquishVJD = lib.GetFunction('RelinquishVJD');
        @ResetAll = lib.GetFunction('ResetAll');
        @ResetButtons = lib.GetFunction('ResetButtons');
        @ResetPovs = lib.GetFunction('ResetPovs');
        @ResetVJD = lib.GetFunction('ResetVJD');
        @SetAxis = lib.GetFunction('SetAxis');
        @SetBtn = lib.GetFunction('SetBtn');
        @SetContPov = lib.GetFunction('SetContPov');
        @SetDiscPov = lib.GetFunction('SetDiscPov');
        @UpdateVJD = lib.GetFunction('UpdateVJD');
        @vJoyEnabled = lib.GetFunction('vJoyEnabled');
        @vJoyFfbCap = lib.GetFunction('vJoyFfbCap');
    }
}