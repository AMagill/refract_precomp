import 'dart:io';
import 'dart:convert';

void main() {
  final String inFileName  = 'monkey-2.js';
  final String outFileName = 'monkey-2.bof';
  
  var inData = new File(inFileName).readAsStringSync();
  var js = JSON.decode(inData);
  
  var indices  = new List<int>();
  var vertices = new List<List<double>>();
  jsonToBufs(js, indices, vertices);
  
  var outputObj = {
    "metadata"      : {
      "format"        : "Buffer Object Format",
      "formatVersion" : 1.0,
      "elements"      : {
        "Position"      : 3,
        "Normal"        : 3,
        "NormalThick"   : 1,
      }
    },
    "indices"       : indices,
    "attributes"    : {
      "Position"      : vertices[0],
      "Normal"        : vertices[1],
      "NormalThick"   : [],
    }
  };
  
  var outputData = JSON.encode(outputObj);
  new File(outFileName).writeAsStringSync(outputData);
}

void jsonToBufs(var js, List<int> indices, List<List<double>> vertices) {
  if (js['metadata']['formatVersion'] != 3.1)
    throw new Exception('Unsupported file format.');

  var faces   = js['faces'];
  var verts   = js['vertices'];
  var normals = js['normals'];
  var colors  = js['colors'];
  var nUvLayers = 0;
  
  for (int i = 0; i < js['uvs'].length; i++)
    if (js['uvs'][i].isNotEmpty()) nUvLayers++;
  
  //var indices = new List<int>();
  var outVerts = new List<double>();
  var outNorms = new List<double>();
  var uniques  = {};

  // Read in all the indices from the face array
  int offset = 0, nVerts = 0;
  while (offset < faces.length) {
    var type = faces[offset++];
    
    bool isQuad         = (type & 1<<0) != 0;
    bool hasMaterial    = (type & 1<<1) != 0;
    bool hasFaceUv      = (type & 1<<2) != 0;
    bool hasVertUv      = (type & 1<<3) != 0;
    bool hasFaceNormal  = (type & 1<<4) != 0;
    bool hasVertNormal  = (type & 1<<5) != 0;
    bool hasFaceColor   = (type & 1<<6) != 0;
    bool hasVertColor   = (type & 1<<7) != 0;

    var ptrs = [];
    for (int i = 0; i < (isQuad?4:3); i++)
      ptrs.add([faces[offset++], -1]);
    
    
    if (hasMaterial)    offset++;    
    if (hasFaceUv)      offset++;    
    if (hasVertUv)      offset += isQuad?4:3;
    if (hasFaceNormal)  offset++;
    if (hasVertNormal) {
      for (var ptr in ptrs)
        ptr[1] = faces[offset++];
    }
    if (hasFaceColor) offset++;
    if (hasVertColor) offset += isQuad?4:3;
    
    // Get indexes
    var uniqueIndexes = [];
    for (var ptr in ptrs) {
      var ptrString = ptr.toString();
      if (!uniques.containsKey(ptrString)) {
        uniqueIndexes.add(uniques.length);
        uniques[ptrString] = uniques.length;
        
        outVerts.add(verts[ptr[0]*3+0].toDouble());
        outVerts.add(verts[ptr[0]*3+1].toDouble());
        outVerts.add(verts[ptr[0]*3+2].toDouble());
        
        outNorms.add(normals[ptr[1]*3+0].toDouble());
        outNorms.add(normals[ptr[1]*3+1].toDouble());
        outNorms.add(normals[ptr[1]*3+2].toDouble());
      } else {
        uniqueIndexes.add(uniques[ptrString]);
      }
    }
        
    if (isQuad) {
      indices.add(uniqueIndexes[0]);
      indices.add(uniqueIndexes[1]);
      indices.add(uniqueIndexes[2]);
      indices.add(uniqueIndexes[0]);
      indices.add(uniqueIndexes[2]);
      indices.add(uniqueIndexes[3]);
    } else {
      indices.add(uniqueIndexes[0]);
      indices.add(uniqueIndexes[1]);
      indices.add(uniqueIndexes[2]);
    }
  }

  vertices.add(outVerts);
  vertices.add(outNorms);
}
