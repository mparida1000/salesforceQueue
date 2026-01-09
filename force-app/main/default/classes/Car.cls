public class Car implements Vehicle, Engine, Steering, Wheel{

    public Integer getVehicleCode(String Name){
        return 0;
    }
    
    public String getColor(Integer colorCode){
        return 'Blue';
    }
    
    public Integer getHP(Integer cc){
        return 1000;
    }
    
    public Integer getRPM(Integer numberOfValves){
        return 3000;
    }
}