module Orientdb4r

  # Version history.
  VERSION_HISTORY = [
    ['0.2.7', '2012-07-07', "Added method Client#class_exists?"],
    ['0.2.6', '2012-07-03', "BF #8, BF #6"],
    ['0.2.5', '2012-07-01', "Added 'get_database' into database CRUD"],
    # v-- https://groups.google.com/forum/?fromgroups#!topic/orient-database/5MAMCvFavTc
    ['0.2.4', '2012-06-26', "Added session management"],
    ['0.2.3', '2012-06-24', "Documents received by a query are kind of Orientdb4r::DocumentMetadata"],
    # v-- https://groups.google.com/forum/?fromgroups#!topic/orient-database/jK4EZd068AE
    # v-- https://groups.google.com/forum/?fromgroups#!topic/orient-database/nJOAsgwSnKI
    ['0.2.2', '2012-06-23', "Added support for server version detection [r5913]"],
    ['0.2.1', '2012-06-19', "Fixed linked property definition"],
    ['0.2.0', '2012-06-12', "Introduces document's CRUD operations"],
    ['0.1.2', '2012-06-10', 'Introduces new OClass module'],
    ['0.1.1', '2012-06-08', 'First working version (including unit tests) released at github.com'],
    ['0.1.0', '2012-06-02', 'Initial version on Ruby-1.9.3p194 and OrientDB-1.0.0']
  ]

  # Current version.
  VERSION = VERSION_HISTORY[0][0]

end
