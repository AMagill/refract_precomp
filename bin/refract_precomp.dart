import 'dart:io';
import 'dart:convert';


void main() {
  final String inFileName  = 'monkey-2.js';
  final String outFileName = 'monkey-2.bb';
  
  var inData = new File(inFileName).readAsStringSync();
  var js = JSON.decode(inData);
  
  var indices  = new List<int>();
  var vertices = new List<List<double>>();
  jsonToBufs(js, indices, vertices);
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
    var ptrs;
    
    if (isQuad) {
      ptrs = [new _UniqueVertIndexes(vert: faces[offset++]),
              new _UniqueVertIndexes(vert: faces[offset++]),
              new _UniqueVertIndexes(vert: faces[offset++]),
              new _UniqueVertIndexes(vert: faces[offset++])];
    } else {
      ptrs = [new _UniqueVertIndexes(vert: faces[offset++]),
              new _UniqueVertIndexes(vert: faces[offset++]),
              new _UniqueVertIndexes(vert: faces[offset++])];
    }
    
    if (hasMaterial) {
      var mat = faces[offset++];
      for (var ptr in ptrs) 
        ptr.mat = mat; 
    }
    
    if (hasFaceUv) {
      var uv = faces[offset++];
      for (var ptr in ptrs)
        ptr.uv = uv;
    }
    
    if (hasVertUv) {
      for (var ptr in ptrs)
        ptr.uv = faces[offset++];
    }
    
    if (hasFaceNormal) {
      var norm = faces[offset++];
      for (var ptr in ptrs)
        ptr.norm = norm;
    }
    
    if (hasVertNormal) {
      for (var ptr in ptrs)
        ptr.norm = faces[offset++];
    }
    
    if (hasFaceColor) {
      var color = faces[offset++];
      for (var ptr in ptrs)
        ptr.color = color;
    }
    
    if (hasVertColor) {
      for (var ptr in ptrs)
        ptr.color = faces[offset++];
    }
    
    // Now keep all the unique combinations
    for (var ptr in ptrs) {
      ptr.index = nVerts++;
      outVerts.add(verts[ptr.vert*3+0].toDouble());
      outVerts.add(verts[ptr.vert*3+1].toDouble());
      outVerts.add(verts[ptr.vert*3+2].toDouble());
      
      outNorms.add(normals[ptr.norm*3+0].toDouble());
      outNorms.add(normals[ptr.norm*3+1].toDouble());
      outNorms.add(normals[ptr.norm*3+2].toDouble());
    }
    
    if (isQuad) {
      indices.add(ptrs[0].index);
      indices.add(ptrs[1].index);
      indices.add(ptrs[2].index);
      indices.add(ptrs[0].index);
      indices.add(ptrs[2].index);
      indices.add(ptrs[3].index);
    } else {
      indices.add(ptrs[0].index);
      indices.add(ptrs[1].index);
      indices.add(ptrs[2].index);
    }
  }
  
  //vertices = new List<List<double>>();
  vertices.add(outVerts);
  vertices.add(outNorms);

}

class _UniqueVertIndexes {
  int vert, mat, norm, id, color, index;
  _UniqueVertIndexes({this.vert: -1, this.mat: -1, this.norm: -1, 
                      this.id:   -1, this.color: -1});
  int get hashCode {
    int result = 17;
    result = 37 * result * vert.hashCode;
    result = 37 * result * mat.hashCode;
    result = 37 * result * norm.hashCode;
    result = 37 * result * id.hashCode;
    result = 37 * result * color.hashCode;
    return result;
  }
  bool operator==(other) {
    return this.vert  == other.vert &&
           this.mat   == other.mat  &&
           this.norm  == other.norm &&
           this.id    == other.id   &&
           this.color == other.color;
  }
}