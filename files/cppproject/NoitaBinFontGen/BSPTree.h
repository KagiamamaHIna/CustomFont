#pragma once
#include "ImageLoad.h"
#include <stack>
#include <iostream>

namespace image {
	class BSPTree {
	public:
		BSPTree(int channels, int widthMax = 4096, int heightMax = 4096) : channels{ channels }, StartWidth{ widthMax } {
			Root = new Node(0, 0, widthMax, heightMax);
		}
		virtual ~BSPTree();
		struct InsertResult {
			InsertResult(bool flag = false, int x = 0, int y = 0) :flag{ flag }, x{ x }, y{ y } {}
			bool flag;
			int x;
			int y;
		};
		bool StaticWidth = true;//让宽度不再动态分配，设置一个良好的数值(4096)可以让Noita加载的时候避免崩溃
		InsertResult insert(stb_image& inputImg);
		stb_image Create();

		BSPTree(const BSPTree&) = delete;
		BSPTree(BSPTree&&) = delete;
		BSPTree& operator=(BSPTree&& src) = delete;
	private:
		struct Node {
			Node(int x = 0, int y = 0, int w = 0, int h = 0) :x{ x }, y{ y }, w{ w }, h{ h } {}
			~Node() {
				if (img) {
					delete img;
				}
			}
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
		int StartWidth;
		Node* Root = nullptr;
		int channels;
	};
}

