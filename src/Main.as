void Main() {
    print("AKN");
    vJoy::Initialize();
}

bool enabled = true;

int neutralSteer = 16384;
int steerAngle = neutralSteer;

bool leftDown = false;
bool rightDown = false;
bool realLeft = false;
bool realRight = false;

[Setting name="Time delay for full steer"]
float secondsToFullSteer = 0.3;
[Setting name="Time delay for resetting to neutral steering"]
float secondsToNeutral = 0.2;

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    // print("Key pressed: " + tostring(key));
    if(key == VirtualKey::A) {
        leftDown = down;
    }
    if(key == VirtualKey::D) {
        rightDown = down;
    }
    if(key == VirtualKey::Left) {
        realLeft = down;
    }
    if(key == VirtualKey::Right) {
        realRight = down;
    }
    if(key == VirtualKey::Tab && down) {
        if(!enabled) {
            vJoy::SetAxis(vJoy::Axis::X, neutralSteer);
            enabled = true;
        } else {
            enabled = false;
        }
    }

    return UI::InputBlocking::DoNothing;
}

void Update(float elapsedMs) {
    if(realLeft) {
        steerAngle = neutralSteer;
        vJoy::SetAxis(vJoy::Axis::X, 0);
        return;
    }
    if(realRight) {
        steerAngle = neutralSteer;
        vJoy::SetAxis(vJoy::Axis::X, neutralSteer * 2);
        return;
    }
    int adjustRate;
    if(secondsToFullSteer != 0)
        adjustRate = int(float(neutralSteer) / secondsToFullSteer / 1000 * elapsedMs);
    else 
        adjustRate = neutralSteer * 2;
    // print(tostring(adjustRate));
    if(leftDown) {
        if(steerAngle > neutralSteer)
            steerAngle = neutralSteer;
        steerAngle -= adjustRate;
        if(steerAngle < 0)
            steerAngle = 0;
    }
    if(rightDown) {
        if(steerAngle < neutralSteer)
            steerAngle = neutralSteer;
        steerAngle += adjustRate;
        if(steerAngle > neutralSteer * 2)
            steerAngle = neutralSteer * 2;
    }
    if(!leftDown && !rightDown) {
        int adjustRateDown;
        if(secondsToNeutral != 0)
            adjustRateDown = int(float(neutralSteer) / secondsToNeutral / 1000 * elapsedMs);
        else 
            adjustRateDown = neutralSteer * 2;
        // nothing held
        int differenceToNeutral = steerAngle - neutralSteer;
        // print("Diff: " + differenceToNeutral);
        if(differenceToNeutral > 0) {
            // right of neutral
            steerAngle -= Math::Min(differenceToNeutral, adjustRateDown);
        } else if(differenceToNeutral < 0) {
            // left of neutral
            steerAngle += Math::Min(-differenceToNeutral, adjustRateDown);
        }
    }
    // print(tostring(steerAngle));
    vJoy::SetAxis(vJoy::Axis::X, steerAngle);
}

void Render() {
    // vJoy::RenderDebugWindow();
}