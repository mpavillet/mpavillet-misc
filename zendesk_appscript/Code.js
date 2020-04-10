function getAuthType() {
  return {
    type: "NONE"
  };
}

function getConfig() {
  return {
    subdomainRequired: true
  };
}

function getSchema() {
  return {
    schema: [
      {
        name: 'id',
        label: 'ID',
        dataType: 'NUMBER',
        semantics: {
          conceptType: 'DIMENSION'
        }
      },
      {
        name: 'name',
        label: 'Name',
        dataType: 'STRING',
        semantics: {
          conceptType: 'DIMENSION'
        }
      },
      {
        name: 'email',
        label: 'Email',
        dataType: 'STRING',
        semantics: {
          conceptType: 'DIMENSION'
        }
      },
      {
        name: 'created_at',
        label: 'created_at (date + hour)',
        dataType: 'STRING',
        semantics: {
          conceptType: 'DIMENSION',
          semanticGroup: 'DATETIME',
          semanticType: 'YEAR_MONTH_DAY_HOUR'
        }
      },
      {
        name: 'updated_at',
        label: 'updated_at (date + hour)',
        dataType: 'STRING',
        semantics: {
          conceptType: 'DIMENSION',
          semanticGroup: 'DATETIME',
          semanticType: 'YEAR_MONTH_DAY_HOUR'
        }
      }
      ]
    }
  };


function getData(request) {
  // Prepare the schema for the fields requested.
  var dataSchema = [];
  var fixedSchema = getSchema().schema;
  request.fields.forEach(function(field) {
    for (var i = 0; i < fixedSchema.length; i++) {
      if (fixedSchema[i].name == field.name) {
        dataSchema.push(fixedSchema[i]);
        break;
      }
    }
  });

// We'll query Spotify API here. For now let's just return two mocked records
  var mockedData = {
    users: [
    {
    id: 2763661739,
    name: "Marion Pavillet",
    email: "mpavillet@zendesk.com",
    created_at: "2016-04-16T11:20:54Z",
    updated_at: "2020-04-10T20:05:22Z"

    },
    {
    id: 2763661839,
    name: "Sample customer",
    email: "customer@example.com",
    created_at: "2016-04-16T11:20:57Z",
    updated_at: "2018-08-22T21:30:07Z"
    },
    {
    id: 14224653085,
    name: "Romain Endelin",
    email: "rendelin@zendesk.com",
    created_at: "2017-07-11T09:23:16Z",
    updated_at: "2020-02-26T05:46:00Z"
    }
    ]

  };


// Prepare the tabular data.
  var data = [];
  mockedData.users.forEach(function(props) {
    var values = [];
    var createdTime = new Date(play.created_at);
    var updatedTime = new Date(play.updated_at);
    // Google expects YYMMDD format
    var createdAtDate = createdTime.toISOString().slice(0, 10).replace(/-/g, "");
    var updatedAtDate = updatedTime.toISOString().slice(0, 10).replace(/-/g, "");
    // Provide values in the order defined by the schema.
    dataSchema.forEach(function(field) {
      switch (field.id) {
      case 'id':
        values.push(props.id);
        break;
      case 'name':
        values.push(props.name);
        break;
      case 'email':
        values.push(props.email);
        break;
      case 'created_at':
        values.push(
          createdAtDate +
          (createdTime.getHours() < 10 ? '0' : '') + createdTime.getHours()
        );
        break;
      case 'created_at_date':
        values.push(createdAtDate);
        break;
        case 'updated_at':
          values.push(
            updatedAtDate +
            (updatedTime.getHours() < 10 ? '0' : '') + updatedTime.getHours()
          );
          break;
        case 'updated_at_date':
          values.push(updatedAtDate);
          break;
      }
    });
    data.push({
      values: values
    });
  });
return {
    schema: dataSchema,
    rows: data
  };
}

function isAdminUser() {
  return true;
}
