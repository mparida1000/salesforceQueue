public class Bike implements Vehicle, Engine, Wheel{
    
public Integer getVehicleCode(String Name){
        return 10;
    }
    
    public String getColor(Integer colorCode){
        return 'Red';
    }
    
    public Integer getHP(Integer cc){
        return 300;
    }
    
    public Integer getRPM(Integer numberOfValves){
        return 6000;
    }
}