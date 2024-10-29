namespace TweetTrack.Common.Models;

public class Bird : BaseModel
{
    public string Name { get; set; }
    public string Base64Picture { get; set; }
    public string Description { get; set; }
}