#pragma once
#include "ImageLoad.h"
#include <stack>
#include <iostream>

namespace image {
	class BSPTree {
	public:
		BSPTree(int channels, int widthMax = 4096, int heightMax = 4096) : channels{ channels } {
			Root = new Node(0, 0, widthMax, heightMax);
		}
		virtual ~BSPTree();
		struct InsertResult {
			InsertResult(bool flag = false, int x = 0, int y = 0) :flag{ flag }, x{ x }, y{ y } {}
			bool flag;
			int x;
			int y;
		};

		InsertResult insert(stb_image& inputImg);
		stb_image Create();
	private:
		struct Node {
			Node(int x = 0, int y = 0, int w = 0, int h = 0) :x{ x }, y{ y }, w{ w }, h{ h } {}
			BSPTree::InsertResult insert(stb_image& img);//返回值代表这次插入是否成功
			int x;
			int y;
			int w;
			int h;
			bool used = false;//两边都被占用了那这个也应该是被占用了
			stb_image* img = nullptr;

			Node* left = nullptr;
			Node* right = nullptr;
		};

		Node* Root = nullptr;
		int channels;
	};
}

