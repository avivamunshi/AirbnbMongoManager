# DATA514_Airbnb
The following are the codes that we used to implement our system. A copy of the same can be found in "Codes.txt" file as well.

### Q1 AirBnB search: Display list of stays in Portland, OR with details: name, neighbourhood, room type, how many guests it accommodates, property type and amenities, per night’s cost and is available for the next two days in descending #order of rating. 
```
db.calendar.aggregate([
  {
    $match: {
      city: "Portland",
      date: {
        $gte: ISODate("2023-06-06T00:00:00Z"),
        $lte: ISODate("2023-06-07T23:59:59Z")
      },
      available: true
    }
  },
  {
    $lookup: {
      from: "listings",
      localField: "listing_id",
      foreignField: "id",
      as: "listing"
    }
  },
  {
    $unwind: "$listing"
  },
  {
    $sort: {
      "listing.review_scores_rating": -1
    }
  },
  {
    $project: {
      _id: 0,
      name: "$listing.name",
      neighbourhood: "$listing.neighbourhood_cleansed",
      room_type: "$listing.room_type",
      accommodates: "$listing.accommodates",
      property_type: "$listing.property_type",
      amenities: "$listing.amenities",
      price: "$price"
    }
  }
])
```
### Q2 Are there any neighbourhoods in any of the cities that don’t have any listings?
```
db.neighborhoods.aggregate([
  {
    $lookup: {
      from: "listings",
      localField: "neighbourhood",
      foreignField: "neighbourhood_cleansed",
      as: "listings"
    }
  },
  {
    $match: {
      listings: { $eq: [] }
    }
  },
  {
    $project: {
      _id: 0,
      neighbourhood: "$neighbourhood",
      city: "$city"
    }
  }
])
```
### Q3 Availability for booking: For “Entire home/apt” type listings in Salem provide it’s availability estimate for each month – which chunks of time are bookable? Display listing’s name, whether it’s Entire home/apt, month, availability “from – to” date/or just date if minimum nights is 1, and minimum #nights. 
```
debugger.Listings.aggregate(
[
  {
    $match:
      /**
       * query: The query in MQL.
       */
      {
        room_type: "Entire home/apt",
        city: "Salem",
      },
  },
  {
    $lookup:
      /**
       * from: The target collection.
       * localField: The local join field.
       * foreignField: The target join field.
       * as: The name for the results.
       * pipeline: Optional pipeline to run on the foreign collection.
       * let: Optional variables to use in the pipeline field stages.
       */
      {
        from: "Calendar",
        localField: "id",
        foreignField: "listing_id",
        as: "cal",
      },
  },
  {
    $unwind:
      /**
       * path: Path to the array field.
       * includeArrayIndex: Optional name for index.
       * preserveNullAndEmptyArrays: Optional
       *   toggle to unwind null and empty values.
       */
      {
        path: "$cal",
      },
  },
  {
    $addFields:
      /**
       * newField: The new field name.
       * expression: The new field expression.
       */
      {
        // Stage 4: Extract date components and add "Is Entire home/apt" field
        month: {
          $month: "$cal.date",
        },
        day: {
          $dayOfMonth: "$cal.date",
        },
        year: {
          $year: "$cal.date",
        },
        "Is Entire home/apt": "Yes",
      },
  },
  {
    $group:
      /**
       * _id: The id of the group.
       * fieldN: The first field name.
       */
      {
        // Stage 5: Group by name, "Is Entire home/apt", and month
        _id: {
          name: "$name",
          "Is Entire home/apt":
            "$Is Entire home/apt",
          month: "$month",
        },
        availability: {
          $push: {
            date: "$cal.date",
            available: "$cal.available",
            minimum_nights: "$cal.minimum_nights",
          },
        },
        minimum_nights: {
          $min: "$cal.minimum_nights",
        },
      },
  },
  {
    $addFields:
      /**
       * newField: The new field name.
       * expression: The new field expression.
       */
      {
        //Performs logic for determining availability
        date_availability: {
          $map: {
            input: "$availability",
            as: "item",
            in: {
              $cond: [
                // Find a start date that is available
                {
                  $eq: ["$$item.available", true],
                },
                {
                  $cond: [
                    // If min nights is 1, store just that value
                    {
                      $eq: [
                        "$$item.minimum_nights",
                        1,
                      ],
                    },
                    {
                      date: {
                        $dateToString: {
                          date: "$$item.date",
                          format: "%Y-%m-%d",
                        },
                      },
                    },
                    // so min nights > 1
                    {
                      $cond: [
                        // (Check if range is large enough) and start/end dates are in the same month
                        {
                          $and: [
                            {
                              $eq: [
                                //check that start and end date months are the same
                                {
                                  $month: {
                                    $dateAdd: {
                                      startDate:
                                        "$$item.date",
                                      unit: "day",
                                      amount: {
                                        $subtract:
                                          [
                                            "$$item.minimum_nights",
                                            1,
                                          ],
                                      },
                                    },
                                  },
                                },
                                {
                                  $month:
                                    "$$item.date", // start day month
                                },
                              ],
                            },
                            {
                              $eq: [
                                {
                                  $size: {
                                    $filter: {
                                      input: {
                                        $range: [
                                          {
                                            $indexOfArray:
                                              [
                                                "$availability.date",
                                                "$$item.date",
                                              ],
                                          },
                                          {
                                            $add: [
                                              {
                                                $indexOfArray:
                                                  [
                                                    "$availability.date",
                                                    "$$item.date",
                                                  ],
                                              },
                                              {
                                                $subtract:
                                                  [
                                                    "$$item.minimum_nights",
                                                    1,
                                                  ],
                                              },
                                            ],
                                          },
                                        ],
                                      },
                                      as: "index",
                                      cond: {
                                        $eq: [
                                          {
                                            $arrayElemAt:
                                              [
                                                "$availability.available",
                                                "$$index",
                                              ],
                                          },
                                          true,
                                        ],
                                      },
                                    },
                                  },
                                },
                                {
                                  $subtract: [
                                    "$$item.minimum_nights",
                                    1,
                                  ],
                                },
                              ],
                            },
                          ],
                        },
                        {
                          // Store date range
                          date: {
                            $concat: [
                              {
                                $dateToString: {
                                  date: "$$item.date",
                                  //start date
                                  format:
                                    "%Y-%m-%d",
                                },
                              },
                              " - ",
                              {
                                $dateToString: {
                                  date: {
                                    //end date
                                    $dateAdd: {
                                      startDate:
                                        "$$item.date",
                                      unit: "day",
                                      amount: {
                                        $subtract:
                                          [
                                            "$$item.minimum_nights",
                                            1,
                                          ],
                                      },
                                    },
                                  },
                                  format:
                                    "%Y-%m-%d",
                                },
                              },
                            ],
                          },
                        },
                        // Otherwise, do nothing
                        null,
                      ],
                    },
                  ],
                },
                // If start date isn't available, do nothing
                null,
              ],
            },
          },
        },
      },
  },
  {
    $addFields:
      /**
       * newField: The new field name.
       * expression: The new field expression.
       */
      {
        //Remove null values from date_availability
        date_availability: {
          $filter: {
            input: "$date_availability",
            as: "item",
            cond: {
              $ne: ["$$item", null],
            },
          },
        },
      },
  },
  {
    $project:
      /**
       * specifications: The fields to
       *   include or exclude.
       */
      {
        _id: 0,
        name: "$_id.name",
        "Is Entire home/apt":
          "$_id.Is Entire home/apt",
        month: "$_id.month",
        minimum_nights: 1,
        //availability: 0,
        date_availability: 1,
      },
  },
  {
    $sort:
      /**
       * Provide any number of field/order pairs.
       */
      {
        name: 1,
        "Is Entire home/apt": -1,
        month: 1,
      },
  },
  {
    $out:
      /**
       * Provide the name of the output collection.
       */
      "Results_1_2",
  },
]
);
```
### Q4 Booking trend for Spring v/s Winter: For “Entire home/apt” type listings in Portland provide it’s availability estimate for each month of Spring and Winter this year.
```
debugger.Listings.aggregate(
  [
    {
      $match:
        /**
         * query: The query in MQL.
         */
        {
          room_type: "Entire home/apt",
          city: "Portland",
        },
    },
    {
      $match:
        /**
         * query: The query in MQL.
         */
        {
          $expr: {
            $and: [
              {
                $gte: [
                  {
                    $month: {
                      $toDate: "$date",
                    },
                  },
                  1,
                ],
              },
              {
                $lte: [
                  {
                    $month: {
                      $toDate: "$date",
                    },
                  },
                  6,
                ],
              },
            ],
          },
        },
    },
    {
      $lookup:
        /**
         * from: The target collection.
         * localField: The local join field.
         * foreignField: The target join field.
         * as: The name for the results.
         * pipeline: Optional pipeline to run on the foreign collection.
         * let: Optional variables to use in the pipeline field stages.
         */
        {
          from: "Calendar",
          localField: "id",
          foreignField: "listing_id",
          as: "cal",
        },
    },
    {
      $unwind:
        /**
         * path: Path to the array field.
         * includeArrayIndex: Optional name for index.
         * preserveNullAndEmptyArrays: Optional
         *   toggle to unwind null and empty values.
         */
        {
          path: "$cal",
        },
    },
    {
      $addFields:
        /**
         * newField: The new field name.
         * expression: The new field expression.
         */
        {
          // Stage 4: Extract date components and add "Is Entire home/apt" field
          month: {
            $month: "$cal.date",
          },
          day: {
            $dayOfMonth: "$cal.date",
          },
          year: {
            $year: "$cal.date",
          },
          "Is Entire home/apt": "Yes",
        },
    },
    {
      $group:
        /**
         * _id: The id of the group.
         * fieldN: The first field name.
         */
        {
          // Stage 5: Group by name, "Is Entire home/apt", and month
          _id: {
            name: "$name",
            "Is Entire home/apt":
              "$Is Entire home/apt",
            month: "$month",
          },
          availability: {
            $push: {
              date: "$cal.date",
              available: "$cal.available",
              minimum_nights: "$cal.minimum_nights",
            },
          },
          minimum_nights: {
            $min: "$cal.minimum_nights",
          },
        },
    },
    {
      $addFields:
        /**
         * newField: The new field name.
         * expression: The new field expression.
         */
        {
          //Performs logic for determining availability
          date_availability: {
            $map: {
              input: "$availability",
              as: "item",
              in: {
                $cond: [
                  // Find a start date that is available
                  {
                    $eq: ["$$item.available", true],
                  },
                  {
                    $cond: [
                      // If min nights is 1, store just that value
                      {
                        $eq: [
                          "$$item.minimum_nights",
                          1,
                        ],
                      },
                      {
                        date: {
                          $dateToString: {
                            date: "$$item.date",
                            format: "%Y-%m-%d",
                          },
                        },
                      },
                      // so min nights > 1
                      {
                        $cond: [
                          // (Check if range is large enough) and start/end dates are in the same month
                          {
                            $and: [
                              {
                                $eq: [
                                  //check that start and end date months are the same
                                  {
                                    $month: {
                                      $dateAdd: {
                                        startDate:
                                          "$$item.date",
                                        unit: "day",
                                        amount: {
                                          $subtract:
                                            [
                                              "$$item.minimum_nights",
                                              1,
                                            ],
                                        },
                                      },
                                    },
                                  },
                                  {
                                    $month:
                                      "$$item.date", // start day month
                                  },
                                ],
                              },
                              {
                                $eq: [
                                  {
                                    $size: {
                                      $filter: {
                                        input: {
                                          $range: [
                                            {
                                              $indexOfArray:
                                                [
                                                  "$availability.date",
                                                  "$$item.date",
                                                ],
                                            },
                                            {
                                              $add: [
                                                {
                                                  $indexOfArray:
                                                    [
                                                      "$availability.date",
                                                      "$$item.date",
                                                    ],
                                                },
                                                {
                                                  $subtract:
                                                    [
                                                      "$$item.minimum_nights",
                                                      1,
                                                    ],
                                                },
                                              ],
                                            },
                                          ],
                                        },
                                        as: "index",
                                        cond: {
                                          $eq: [
                                            {
                                              $arrayElemAt:
                                                [
                                                  "$availability.available",
                                                  "$$index",
                                                ],
                                            },
                                            true,
                                          ],
                                        },
                                      },
                                    },
                                  },
                                  {
                                    $subtract: [
                                      "$$item.minimum_nights",
                                      1,
                                    ],
                                  },
                                ],
                              },
                            ],
                          },
                          {
                            // Store date range
                            date: {
                              $concat: [
                                {
                                  $dateToString: {
                                    date: "$$item.date",
                                    //start date
                                    format:
                                      "%Y-%m-%d",
                                  },
                                },
                                " - ",
                                {
                                  $dateToString: {
                                    date: {
                                      //end date
                                      $dateAdd: {
                                        startDate:
                                          "$$item.date",
                                        unit: "day",
                                        amount: {
                                          $subtract:
                                            [
                                              "$$item.minimum_nights",
                                              1,
                                            ],
                                        },
                                      },
                                    },
                                    format:
                                      "%Y-%m-%d",
                                  },
                                },
                              ],
                            },
                          },
                          // Otherwise, do nothing
                          null,
                        ],
                      },
                    ],
                  },
                  // If start date isn't available, do nothing
                  null,
                ],
              },
            },
          },
        },
    },
    {
      $addFields:
        /**
         * newField: The new field name.
         * expression: The new field expression.
         */
        {
          //Remove null values from date_availability
          date_availability: {
            $filter: {
              input: "$date_availability",
              as: "item",
              cond: {
                $ne: ["$$item", null],
              },
            },
          },
        },
    },
    {
      $project:
        /**
         * specifications: The fields to
         *   include or exclude.
         */
        {
          _id: 0,
          name: "$_id.name",
          "Is Entire home/apt":
            "$_id.Is Entire home/apt",
          month: "$_id.month",
          minimum_nights: 1,
          //availability: 0,
          date_availability: 1,
        },
    },
    {
      $sort:
        /**
         * Provide any number of field/order pairs.
         */
        {
          name: 1,
          "Is Entire home/apt": -1,
          month: 1,
        },
    },
    {
      $out:
        /**
         * Provide the name of the output collection.
         */
        "Results_2_1",
    },
  ]
);
```
### Q5 Booking Trend: For each city, how many reviews are received for December of each year?
```
db.reviews.aggregate([
  {
    $project: {
        date :1,
  	month: {$month : "$date"},
 	year: { $year: "$date" },
  	city: 1,
  	comments: 1
    }
  },
  {
    $match: {
      $expr: {
        $eq: [{ $month: "$date" }, 12]
      }
    }
  },
  {
    $group: {
      _id: {
        year: "$year",
        city: "$city"
      },
      reviewCount: { $sum: 1 }
    }
  },
  {
    $project: {
      _id: 0,
      year: "$_id.year",
      city: "$_id.city",
      reviewCount: 1
    }
  },
  {
     $sort: {
       city: 1,
       year: 1

     }
  }
])
```
### Q6 Reminder to Book again: Are there any listings that have received more than #three reviews from the same reviewer within a month? Additionally, are there any other listings by the same host that can be suggested? If so, please display the #listing's name, URL, description, host's name, reviewer's name, whether it was previously booked, availability days, minimum nights for booking, and maximum #nights for booking. (Slightly modified from the actual query)
```
db.reviews.aggregate([
  {
    $group: {
      _id: {
        listing_id: "$listing_id",
        reviewer_id: "$reviewer_id",
        month: { $month: "$date" }
      },
      count: { $sum: 1 }
    }
  },
  {
    $match: {
      count: { $gt: 3 }
    }
  },
  {
    $lookup: {
      from: "listings",
      localField: "_id.listing_id",
      foreignField: "id",
      as: "listing"
    }
  },
  {
    $lookup: {
      from: "reviews",
      localField: "_id.listing_id",
      foreignField: "listing_id",
      as: "previous_reviews"
    }
  },
  {
    $lookup: {
      from: "listings",
      localField: "listing.host_id",
      foreignField: "host_id",
      as: "other_listings"
    }
  },
  {
    $match: {
      "other_listings.id": { $ne: "$_id.listing_id" }
    }
  },
  {
    $project: {
      _id: 0,
      listing_id: "$_id.listing_id",
      reviewer_id: "$_id.reviewer_id",
      month: "$_id.month",
      listing_name: { $arrayElemAt: ["$listing.name", 0] },
      listing_url: { $arrayElemAt: ["$listing.listing_url", 0] },
      listing_description: { $arrayElemAt: ["$listing.description", 0] },
      host_name: { $arrayElemAt: ["$listing.host_name", 0] },
      reviewer_name: { $arrayElemAt: ["$previous_reviews.reviewer_name", 0] },
      previously_booked: { $cond: [{ $gte: ["$count", 4] }, true, false] },
      availability_days: "$listing.availability_365",
      min_nights: "$listing.minimum_nights",
      max_nights: "$listing.maximum_nights",
      other_listings: {
        $map: {
          input: "$other_listings",
          as: "other",
          in: {
            listing_name: "$$other.name",
            listing_url: "$$other.listing_url",
            listing_description: "$$other.description",
            host_name: "$$other.host_name",
            reviewer_name: "$$other.reviewer_name",
            previously_booked: "$$other.previously_booked",
            availability_days: "$$other.availability_365",
            min_nights: "$$other.minimum_nights",
            max_nights: "$$other.maximum_nights"
          }
        }
      }
    }
  }
])
```

## We’ve identified 2 other questions we would like to add. They are as follows:
### Q7 Hosts with the Most Listings:Display the list of hosts with the most number of listings.
```
[
  {
    $group:
      /**
       * grouping documents by host_id field
       * count of listings for each host
       */
      {
        _id: "$host_id",
        count: {
          $sum: 1,
        },
      },
  },
  {
    $sort:
      /**
       * sort in desc order
       */
      {
        count: -1,
      },
  },
  {
    $limit:
      /**
       * top 5 hosts
       */
      5,
  },
]
```

### Q8 Average Review Scores by Property Type: What is the average review score for each property type?
```
[
  {
    $match:
      /**
  filters out documents where 
  review_scores_rating field is "NA" 
  and 
  property_type field is not null.
  */
      {
        review_scores_rating: {
          $ne: "NA",
        },
        property_type: {
          $ne: null,
        },
      },
  },
  {
    $group:
      /**
  groups the documents by the 
  property_type field and 
  calculates the average review scores 
  using the $avg aggregation operator. 
   $toDouble operator is used to 
  convert the review_scores_rating 
  field to a numeric value.
  */
      {
        _id: "$property_type",
        avg_review_scores: {
          $avg: {
            $toDouble: "$review_scores_rating",
          },
        },
      },
  },
]
```
