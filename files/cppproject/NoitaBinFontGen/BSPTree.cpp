#include "BSPTree.h"

namespace image {
	BSPTree::~BSPTree() {
		if (Root == nullptr) {
			return;
		}
		std::stack<Node*> nodeStack;
		nodeStack.push(Root);
		while (!nodeStack.empty()) {
			Node* node = nodeStack.top();
			nodeStack.pop();

			if (node->left) {
				nodeStack.push(node->left);
			}
			if (node->right) {
				nodeStack.push(node->right);
			}
			delete node;
		}
	}

	stb_image BSPTree::Create() {
		//假设正确设置了x和y
		std::stack<Node*> nodeStack;
		std::stack<Node*> imgStack;
		nodeStack.push(Root);
		int widthMax = 0;
		int heightMax = 0;
		//迭代法检测含有图像的节点
		while (!nodeStack.empty()) {
			Node* node = nodeStack.top();
			nodeStack.pop();

			if (node->left) {
				nodeStack.push(node->left);
			}
			if (node->right) {
				nodeStack.push(node->right);
			}

			if (node->img) {
				imgStack.push(node);
				stb_image* img = node->img;
				if (node->y + img->GetHeight() > heightMax) {
					heightMax = node->y + img->GetHeight();
				}
				if (node->x + img->GetWidth() > widthMax) {
					widthMax = node->x + img->GetWidth();
				}
				//std::cout << "node x:" << node->x << " node y:" << node->y << '\n';
				//std::cout << "width:" << img->GetWidth() << " height:" << img->GetHeight() << '\n';
				//std::cout << "node w:" << node->w << " node h:" << node->h << '\n';
			}
		}
		stb_image result(widthMax, heightMax, channels);//主图片

		while (!imgStack.empty()) {
			Node* node = imgStack.top();
			stb_image* img = node->img;
			imgStack.pop();
			for (int x = 0; x < img->GetWidth(); x++) {
				for (int y = 0; y < img->GetHeight(); y++) {//深拷贝
					result.SetPixel(node->x + x, node->y + y, img->GetPixel(x, y));
				}
			}
		}
		return result;
	}

	BSPTree::InsertResult BSPTree::insert(stb_image& inputImg) {
		if (inputImg.GetChannels() != channels) {
			return BSPTree::InsertResult(false, 0, 0);
		}
		return Root->insert(inputImg);
	}

	BSPTree::InsertResult BSPTree::Node::insert(stb_image& img) {
		BSPTree::InsertResult result;

		int width = img.GetWidth();
		int height = img.GetHeight();
		if (width > w || height > h || used) {//如果图像宽或图像高过大或已被占用，则插入失败
			return result;
		}

		double InputArea = width * height;//计算面积，用于计算占用率

		std::stack<Node*> nodeStack;
		Node* Current = nullptr;
		double Fragmentation = 0;

		nodeStack.push(this);
		while (!nodeStack.empty()) {//迭代+占用率算法(贪心)，找到最优的足够小节点
			Node* node = nodeStack.top();
			nodeStack.pop();

			if (node->used) {
				continue;
			}
			if (node->left != nullptr && node->right != nullptr) {//未被占用，有子节点，存入栈，下一次循环
				if (node->left->used && node->right->used) {//都为真
					node->used = true;//标记他们的根节点为真，之后就不用检查了
				}
				if (!node->left->used) {//两个单独检查，减少栈的分配与内存消耗
					nodeStack.push(node->left);
				}
				if (!node->right->used) {
					nodeStack.push(node->right);
				}
				continue;
			}
			//当目标没有子节点的时候，检查参数是否符合
			if (width > node->w || height > node->h) {
				continue;
			}
			double ThisArea = (double)(node->h * node->w) / InputArea;//计算占用率
			if (ThisArea > Fragmentation) {//假如占用率够高，那么存入，选择占用率最高的方案
				Current = node;
				Fragmentation = ThisArea;
				if (Fragmentation == 1) {//满占用率直接退出循环
					break;
				}
			}
		}
		//循环完成后，Current有两个结果，一个是空指针，一个是目标
		if (Current == nullptr) {
			return result;
		}
		if (Fragmentation == 1) {//能占用完全
			Current->img = new stb_image(img);
			used = true;
		}
		else {//不能完全占用，分割出最小且合适的
			int	dw = Current->w - width;
			int	dh = Current->h - height;
			if (dw < dh) {//优先沿长边分割 垂直
				Current->left = new Node(Current->x, Current->y, width, Current->h);
				Current->right = new Node(Current->x + width, Current->y, Current->w - width, Current->h);
				//左节点的右节点的，垂直分割应该采用水平分割
				Current->left->right = new Node(Current->x, Current->y + height, width, Current->left->h - height);

			}
			else {// 水平
				Current->left = new Node(Current->x, Current->y, Current->w, height);
				Current->right = new Node(Current->x, Current->y + height, Current->w, Current->h - height);
				//左节点的右节点的，水平分割应该采用垂直分割
				Current->left->right = new Node(Current->x + width, Current->y, Current->left->w - width, height);
			}
			//单独分割左节点
			Current->left->left = new Node(Current->x, Current->y, width, height);
			Current->left->left->img = new stb_image(img);
			Current->left->left->used = true;
			result.flag = true;
			result.x = Current->x;
			result.y = Current->y;
		}
		return result;
	}
}
