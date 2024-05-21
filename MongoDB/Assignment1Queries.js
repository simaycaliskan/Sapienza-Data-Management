//////////////////////// ASSIGNMENT 1: QUERIES //////////////////////////////

// Query 1: Get the names of the female singers who won the competition and the year they won.  
db.song_data_winner.find(
    { 
       winner_flag: 1,
       gender: 'Female'
    },
    { 
       artist_name: 1,
       year: 1,
       _id: 0
    }
 );
 

// Query 2: Get the songs and their final rankings which got more than 10% of the poll votes
// Calculating the percentages in the poll votes table 
// TODO





// Query 3: Regional analysis of the winner countries
db.song_data.aggregate([
    {
        $lookup: {
            from: "country_data",
            localField: "country",
            foreignField: "country",
            as: "country_data"
        }
    },
    {
        $unwind: "$country_data"
    },
    {
        $match: { final_place: 1 }
    },
    {
        $group: {
            _id: "$country_data.region",
            count: { $sum: 1 }
        }
    },
    {
        $sort: { count: -1 }
    },
    {
        $project: {
            _id: 0,
            region: "$_id",
            count: 1
        }
    }
]);




