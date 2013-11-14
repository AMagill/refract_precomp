import 'dart:io';
import 'dart:convert';
import 'package:vector_math/vector_math.dart';

void main() {
  final String inFileName  = 'monkey-3.js';
  final String outFileName = 'monkey-2.bof';
  
  var inData = new File(inFileName).readAsStringSync();
  var js = JSON.decode(inData);
  
  var indices  = new List<int>();
  var vertices = new List<List<double>>();
  jsonToBufs(js, indices, vertices);
  
  
  // Compute the normal thickness
  var nthick = [];
  var allTriangles = [];
  
  for (int j = 0; j < indices.length; j+=3) {
   allTriangles.add(new Triangle.points(
        new Vector3.array(vertices[0], indices[j+0]*3),
        new Vector3.array(vertices[0], indices[j+1]*3),
        new Vector3.array(vertices[0], indices[j+2]*3)));
  }
  
  for (int i = 0; i < vertices[0].length; i+=3) {
    var maxDist = double.NEGATIVE_INFINITY;
    var ray = new Ray.originDirection(
        new Vector3.array(vertices[0], i),
        -(new Vector3.array(vertices[1], i)));
    
    for (var tri in allTriangles) {
      var dist = ray.intersectsWithTriangle(tri);
      if (dist != null && dist > maxDist)
        maxDist = dist;
    }
    if (maxDist == double.NEGATIVE_INFINITY)
      maxDist = 1000.0;
    nthick.add(maxDist);
  }
  
  var nVertices = vertices[0].length ~/ 3;
  var outputObj = {
    "metadata"      : {
      "format"        : "Buffer Object Format",
      "formatVersion" : 1.0,
      "vertices"      : nVertices,
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
      "NormalThick"   : nthick,
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
