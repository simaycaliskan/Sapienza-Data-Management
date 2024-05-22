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

db.poll_results_all_years.updateMany(
    {},
    [
        {
            $set: {
                Total_Votes: {
                    $sum: [
                        { $ifNull: ["$my_eurovision_scoreboard_points", 0] },
                        { $ifNull: ["$eurovision_world_points", 0] },
                        { $ifNull: ["$eurojury_jury_points", 0] },
                        { $ifNull: ["$eurojury_online_points", 0] },
                        { $ifNull: ["$discord_points", 0] },
                        { $ifNull: ["$wiwiblogs_points", 0] },
                        { $ifNull: ["$ogae_points", 0] }
                    ]
                }
            }
        }
    ]
)
const totalVotesPerYear = db.poll_results_all_years.aggregate([
    {
        $group: {
            _id: "$year",
            Total_Votes_per_Year: { $sum: "$Total_Votes" }
        }
    }
]);

// Convert the aggregation result to a dictionary for easy lookup
const totalVotesPerYearDict = {};
totalVotesPerYear.forEach(item => {
    totalVotesPerYearDict[item._id] = item.Total_Votes_per_Year;
});
for (const [year, totalVotes] of Object.entries(totalVotesPerYearDict)) {
    db.poll_results_all_years.updateMany(
        { year: parseInt(year) },
        {
            $set: { Total_Votes_per_Year: totalVotes }
        }
    );
}
db.poll_results_all_years.updateMany(
    {},
    [
        {
            $set: {
                Percentages: {
                    $multiply: [
                        {
                            $divide: [
                                { $toDouble: "$Total_Votes" },
                                { $toDouble: "$Total_Votes_per_Year" }
                            ]
                        },
                        100
                    ]
                }
            }
        }
    ]
)
db.song_data_winner.aggregate([
    {
        $lookup: {
            from: "poll_results_all_years",
            let: { year: "$year", country: "$country" },
            pipeline: [
                {
                    $match: {
                        $expr: {
                            $and: [
                                { $eq: ["$year", "$$year"] },
                                { $eq: ["$Contestant", "$$country"] }
                            ]
                        }
                    }
                },
                { $project: { Percentages: 1, _id: 0 } }
            ],
            as: "poll_results"
        }
    },
    { $unwind: "$poll_results" },
    { $match: { "poll_results.Percentages": { $gt: 10 } } },
    {
        $project: {
            country: 1,
            song_name: 1,
            final_place: 1,
            Percentages: "$poll_results.Percentages",
            winner_flag: 1
        }
    }
])





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



// Query 4: The songs which got more than 2 percantage of poll results but did not qualify for the final
//Joining tables
db.poll_results_all_years.aggregate([
    {
        $lookup: {
            from: "song_data_winner",
            let: { year: "$year", contestant: "$Contestant" },
            pipeline: [
                {
                    $match: {
                        $expr: {
                            $and: [
                                { $eq: ["$year", "$$year"] },
                                { $eq: ["$country", "$$contestant"] }
                            ]
                        }
                    }
                },
                {
                    $project: {
                        year: 1,
                        country: 1,
                        song_name: 1,
                        qualified_10: 1
                    }
                }
            ],
            as: "song_data"
        }
    },
    { $unwind: "$song_data" },
    {
        $project: {
            year: "$song_data.year",
            country: "$song_data.country",
            song_name: "$song_data.song_name",
            percentages: "$Percentages",
            qualified_10: "$song_data.qualified_10"
        }
    }
])

// Actual query:
db.poll_results_all_years.aggregate([
    {
        $lookup: {
            from: "song_data_winner",
            let: { year: "$year", contestant: "$Contestant" },
            pipeline: [
                {
                    $match: {
                        $expr: {
                            $and: [
                                { $eq: ["$year", "$$year"] },
                                { $eq: ["$country", "$$contestant"] }
                            ]
                        }
                    }
                },
                {
                    $project: {
                        year: 1,
                        country: 1,
                        song_name: 1,
                        qualified_10: 1
                    }
                }
            ],
            as: "song_data"
        }
    },
    { $unwind: "$song_data" },
    {
        $match: {
            "Percentages": { $gt: 2 },
            "song_data.qualified_10": 0
        }
    },
    {
        $project: {
            year: "$song_data.year",
            country: "$song_data.country",
            song_name: "$song_data.song_name",
            percentages: "$Percentages"
        }
    }
])



// Query 5: skip, not necessarily in the top 10 queries


// Query 6: Categorizing the performance of each country based on their median final_place
// Getting the median rankings 

db.song_data.aggregate([
    {
        $group: {
            _id: "$country",
            final_places: { $push: "$final_place" }
        }
    },
    {
        $project: {
            country: "$_id",
            final_places: 1,
            count: { $size: "$final_places" }
        }
    },
    {
        $project: {
            country: 1,
            final_places: 1,
            median_final_place: {
                $let: {
                    vars: {
                        sorted_final_places: { $sortArray: { input: "$final_places", sortBy: 1 } }
                    },
                    in: {
                        $arrayElemAt: [
                            "$$sorted_final_places",
                            { $floor: { $divide: ["$count", 2] } }
                        ]
                    }
                }
            }
        }
    }
])


// Actual query: 
db.song_data.aggregate([
    {
        $group: {
            _id: "$country",
            final_places: { $push: "$final_place" }
        }
    },
    {
        $project: {
            country: "$_id",
            final_places: 1,
            count: { $size: "$final_places" }
        }
    },
    {
        $project: {
            country: 1,
            final_places: 1,
            median_final_place: {
                $let: {
                    vars: {
                        sorted_final_places: { $sortArray: { input: "$final_places", sortBy: 1 } }
                    },
                    in: {
                        $arrayElemAt: [
                            "$$sorted_final_places",
                            { $floor: { $divide: ["$count", 2] } }
                        ]
                    }
                }
            }
        }
    },
    {
        $project: {
            country: 1,
            performance_category: {
                $cond: {
                    if: { $lte: ["$median_final_place", 10] },
                    then: "Top 10",
                    else: {
                        $cond: {
                            if: { $lte: ["$median_final_place", 20] },
                            then: "Top 20",
                            else: "Below Top 20"
                        }
                    }
                }
            }
        }
    }
])



// Query 7: The countries to whom Italy gave 12 points to in any of the years
//Televote

db.Results_all_years.aggregate([
    {
        $match: {
            "Italy": 12,
            "Jury/Televote": "Jury"
        }
    },
    {
        $project: {
            Contestant: 1,
            year: 1,
            "Jury/Televote": 1,
            "Total score": 1,
            "Jury score": 1,
            "Televoting score": 1
        }
    },
    {
        $lookup: {
            from: "winner_data",
            let: { year: "$year", contestant: "$Contestant" },
            pipeline: [
                {
                    $match: {
                        $expr: {
                            $and: [
                                { $eq: ["$years", "$$year"] },
                                { $eq: ["$winner", "$$contestant"] }
                            ]
                        }
                    }
                },
                {
                    $project: {
                        winner: 1
                    }
                }
            ],
            as: "winner_info"
        }
    },
    {
        $unwind: { path: "$winner_info", preserveNullAndEmptyArrays: true }
    },
    {
        $project: {
            Contestant: 1,
            year: 1,
            "Jury/Televote": 1,
            "Total score": 1,
            "Jury score": 1,
            "Televoting score": 1,
            winner: "$winner_info.winner"
        }
    },
    {
        $sort: { year: 1 }
    }
])



//Jury
db.Results_all_years.aggregate([
    {
        $match: {
            "Italy": 12,
            "Jury/Televote": "Jury"
        }
    },
    {
        $project: {
            Contestant: 1,
            year: 1,
            "Jury/Televote": 1,
            "Total score": 1,
            "Jury score": 1,
            "Televoting score": 1
        }
    },
    {
        $lookup: {
            from: "winner_data",
            let: { year: "$year", contestant: "$Contestant" },
            pipeline: [
                {
                    $match: {
                        $expr: {
                            $and: [
                                { $eq: ["$years", "$$year"] },
                                { $eq: ["$winner", "$$contestant"] }
                            ]
                        }
                    }
                },
                {
                    $project: {
                        winner: 1
                    }
                }
            ],
            as: "winner_info"
        }
    },
    {
        $unwind: { path: "$winner_info", preserveNullAndEmptyArrays: true }
    },
    {
        $project: {
            Contestant: 1,
            year: 1,
            "Jury/Televote": 1,
            "Total score": 1,
            "Jury score": 1,
            "Televoting score": 1,
            winner: "$winner_info.winner"
        }
    },
    {
        $sort: { year: 1 }
    }
])



// Query 8: How "Out of Europe" countries vote
db.Results_all_years.aggregate([
    {
        $group: {
            _id: "$Contestant",
            Geo_point_count: { $sum: { $cond: [{ $ifNull: ["$Georgia", false] }, 1, 0] } },
            Geo_total_giving_points: { $sum: "$Georgia" },
            Aze_point_count: { $sum: { $cond: [{ $ifNull: ["$Azerbaijan", false] }, 1, 0] } },
            Aze_total_giving_points: { $sum: "$Azerbaijan" },
            Isr_point_count: { $sum: { $cond: [{ $ifNull: ["$Israel", false] }, 1, 0] } },
            Isr_total_giving_points: { $sum: "$Israel" },
            Aus_point_count: { $sum: { $cond: [{ $ifNull: ["$Australia", false] }, 1, 0] } },
            Aus_total_giving_points: { $sum: "$Australia" }
        }
    },
    {
        $project: {
            Contestant: "$_id",
            Geo_point_count: 1,
            Geo_total_giving_points: 1,
            Aze_point_count: 1,
            Aze_total_giving_points: 1,
            Isr_point_count: 1,
            Isr_total_giving_points: 1,
            Aus_point_count: 1,
            Aus_total_giving_points: 1
        }
    }
])




// Query 9: no need


//Query 10: Analyze the popularity of different music genres for the songs which ended up in top 5.
db.song_data_winner.aggregate([
    {
        $match: {
            final_place: { $lt: 6 }
        }
    },
    {
        $group: {
            _id: {
                style: "$style",
                final_place: "$final_place"
            },
            winner_count: { $sum: 1 }
        }
    },
    {
        $sort: {
            "_id.final_place": 1,
            winner_count: -1
        }
    },
    {
        $project: {
            _id: 0,
            style: "$_id.style",
            final_place: "$_id.final_place",
            winner_count: 1
        }
    }
])


//Query 11:


//Query 12:


//Query 13:

