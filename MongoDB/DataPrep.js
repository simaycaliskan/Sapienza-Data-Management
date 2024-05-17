////////////////// POLL RESULTS ////////////////////////////
// Add year field to each collection
db["2016_poll_results"].updateMany({}, { $set: { year: 2016 } });
db["2017_poll_results"].updateMany({}, { $set: { year: 2017 } });
db["2018_poll_results"].updateMany({}, { $set: { year: 2018 } });
db["2019_poll_results"].updateMany({}, { $set: { year: 2019 } });
db["2021_poll_results"].updateMany({}, { $set: { year: 2021 } });
db["2022_poll_results"].updateMany({}, { $set: { year: 2022 } });
db["2023_poll_results"].updateMany({}, { $set: { year: 2023 } });



db.createCollection("poll_results_all_years");

// Concatenate collections by merging documents into 'poll_results_all_years'
var years = ["2016", "2017", "2018", "2019", "2021", "2022", "2023"];

years.forEach(function(year) {
    db[year + "_poll_results"].find().forEach(function(doc) {
        db.poll_results_all_years.insertOne(doc);
    });
});


////////////////// JURY RESULTS /////////////////////////////

// Add year field to each collection
db["2016_jury_results"].updateMany({}, { $set: { year: 2016 } });
db["2017_jury_results"].updateMany({}, { $set: { year: 2017 } });
db["2018_jury_results"].updateMany({}, { $set: { year: 2018 } });
db["2019_jury_results"].updateMany({}, { $set: { year: 2019 } });
db["2021_jury_results"].updateMany({}, { $set: { year: 2021 } });
db["2022_jury_results"].updateMany({}, { $set: { year: 2022 } });
db["2023_jury_results"].updateMany({}, { $set: { year: 2023 } });


// Create the collection 'jury_results_all_years' if it doesn't exist
db.createCollection("jury_results_all_years");

// Concatenate collections by merging documents into 'jury_results_all_years'
var years = ["2016", "2017", "2018", "2019", "2021", "2022", "2023"];

years.forEach(function(year) {
    db[year + "_jury_results"].find().forEach(function(doc) {
        db.jury_results_all_years.insertOne(doc);
    });
});


////////////////// TELEVOTE RESULTS /////////////////////////////

// Add year field to each collection
db["2016_televote_results"].updateMany({}, { $set: { year: 2016 } });
db["2017_televote_results"].updateMany({}, { $set: { year: 2017 } });
db["2018_televote_results"].updateMany({}, { $set: { year: 2018 } });
db["2019_televote_results"].updateMany({}, { $set: { year: 2019 } });
db["2021_televote_results"].updateMany({}, { $set: { year: 2021 } });
db["2022_televote_results"].updateMany({}, { $set: { year: 2022 } });
db["2023_televote_results"].updateMany({}, { $set: { year: 2023 } });


// Create the collection 'televote_results_all_years' if it doesn't exist
db.createCollection("televote_results_all_years");

// Concatenate collections by merging documents into 'televote_results_all_years'
var years = ["2016", "2017", "2018", "2019", "2021", "2022", "2023"];

years.forEach(function(year) {
    db[year + "_televote_results"].find().forEach(function(doc) {
        db.televote_results_all_years.insertOne(doc);
    });
});


///////////// CONCAT JURY AND TELEVOTE RESULTS INTO ONE TABLE ///////////

// Create the new collection 'Results_all_years' if it doesn't exist
db.createCollection("Results_all_years");

// Merge documents from 'jury_results_all_years' into 'Results_all_years' with 'Jury/Televote' field set to 'Jury'
db.jury_results_all_years.find().forEach(function(doc) {
    doc["Jury/Televote"] = "Jury";
    db.Results_all_years.insertOne(doc);
});

// Merge documents from 'televote_results_all_years' into 'Results_all_years' with 'Jury/Televote' field set to 'Televote'
db.televote_results_all_years.find().forEach(function(doc) {
    doc["Jury/Televote"] = "Televote";
    db.Results_all_years.insertOne(doc);
});


