#include <bits/stdc++.h>

using namespace std;

#define RADIAL 0
#define STRAIGHT 1
//#define DIAGONAL 2
//#define ARC 3

int ATTACKS_GENERATED = 10;

vector<int> DAMAGE_BASE = {1, 10};
vector<int> DAMAGE_SLOPE = {-2, 2};
vector<int> HEIGHT_DIFFERENTIAL = {2, 7};
vector<int> TYPE = {0, 1};
vector<int> OFFSET = {0, 2};
vector<int> DIST = {0, 2};
vector<int> THICKNESS = {0, 2};

int DI[4] = {1, 0, -1, 0};
int DJ[4] = {0, 1, 0, -1};
int OI[4] = {-1, 1, 1, -1};
int OJ[4] = {-1, -1, 1, 1};

struct Direction {
	int x;
	int y;
	Direction(){
		x = 0;
		y = 0;
	}
	Direction(int _x, int _y){
		x=_x;
		y=_y;
	}
	bool isNonzero(){
		return (x!=0 && y!=0);
	}
};

struct Attack {
	int damageBase = 0;
	int damageSlope = 0;
	int heightDifferential = 0;
	int energyCost = 0;
	vector<Direction> squares;
	Direction playerKnockback;
	Direction enemyKnockback;
	
	void setEnergyCost(){
		double value = 0;
		value += ((double) damageBase)/10;
		value *= pow(heightDifferential * 2 + 1, 0.5);
		value *= pow(squares.size(), 0.5);
		if (playerKnockback.isNonzero()){
			value += 5;
		}
		if (enemyKnockback.isNonzero()){
			value += 10;
		}
		energyCost = value;
	}
	string squaresToString(){
		int minX = 0;
		int maxX = 0;
		int minY = 0;
		int maxY = 0;
		for (Direction square : squares){
			minX = min(minX, square.x);
			maxX = max(maxX, square.x);
			minY = min(minY, square.y);
			maxY = max(maxY, square.y);
		}
		vector<vector<char> > squareArr(maxX + 1 - minX, vector<char> (maxY + 1 - minY, ' '));
		for (Direction square : squares){
			squareArr[square.x - minX][square.y - minY] = 'X';
		}
		squareArr[-minX][-minY]='O';
		stringstream ss;
		for (vector<char> & row : squareArr){
			for (char & cell : row){
				ss<<cell;
			}
			ss<<endl;
		}
		return ss.str();
	}
	string toString(){
		stringstream ss;
		ss<<"Damage: "<<damageBase;
		if (damageSlope){
			ss<<" + "<<damageSlope<<" * dh";
		}
		ss<<endl<<"Maximum Height Difference: "<<heightDifferential<<endl;
		ss<<"Energy Cost: "<<energyCost<<endl;
		ss<<endl<<squaresToString();
		return ss.str();
	}
	void print(){
		cout<<toString()<<endl;
	}
};

bool isNonzeroDirection(Direction dir){
	return (dir.x || dir.y);
}

int calcEnergyCost(int damageBase, int heightDifferential, int squares, Direction playerKnockback, Direction enemyKnockback){
	double value = 0;
	value += ((double) damageBase)/5;
	value *= pow(heightDifferential * 2 + 1, 0.5);
	value *= pow(squares, 0.5);
	if (isNonzeroDirection(playerKnockback)){
		value += 10;
	}
	if (isNonzeroDirection(enemyKnockback)){
		value += 20;
	}
	return value/5;
}


vector<Direction> getRadialCells(int offset, int dist, int thickness){
	vector<Direction> cells;
	for (int x=offset+1; x<=offset+dist+1; x++){
		for (int d=0; d<4; d++){
			int i = DI[d] * x;
			int j = DJ[d] * x;
			cells.push_back(Direction(i,j));
			if (thickness > (x-2)){
				for (int y=1; y<x; y++){
					i += OI[d];
					j += OJ[d];
					cells.push_back(Direction(i,j));
				}
			}
		}
	}
	return cells;
}


vector<Direction> getStraightCells(int offset, int dist, int thickness){
	vector<Direction> cells;
	for (int i=offset+1; i<=offset+dist+1; i++){
		for (int j=-thickness; j<=thickness; j++){
			cells.push_back(Direction(i,j));
		}
	}
	return cells;
}

vector<Direction> getSquares(int type, int offset, int dist, int thickness){
	if (type == RADIAL){
		return getRadialCells(offset, dist, thickness);
	}
	else {
		return getStraightCells(offset, dist, thickness);
	}
}

int randOp(vector<int> & vec){
	int lower = vec[0];
	int upper = vec[1];
	return lower + (rand())%(upper - lower + 1);
}

Attack getRandomAttack(){
	Attack attack;
	attack.damageBase = randOp(DAMAGE_BASE);
	attack.damageSlope = randOp(DAMAGE_SLOPE);
	attack.heightDifferential = randOp(HEIGHT_DIFFERENTIAL);
	attack.squares = getSquares(randOp(TYPE), randOp(OFFSET), randOp(DIST), randOp(THICKNESS));
	attack.setEnergyCost();
	return attack;
}

int main(){
	for (int i=0; i<ATTACKS_GENERATED; i++){
		Attack attack = getRandomAttack();
		attack.print();
	}
}