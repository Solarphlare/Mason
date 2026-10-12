# ——— Toolchain ———
CXX      := g++

ifeq ($(OS),Windows_NT)
    DETECTED_OS := Windows
else
    DETECTED_OS := $(shell uname -s)
endif

ifeq ($(DETECTED_OS),Darwin)
CXXFLAGS := -std=c++20 -Wall -Werror -Wpedantic \
             -I/opt/homebrew/include/mongocxx/v_noabi \
			 -I/opt/homebrew/include/bsoncxx/v_noabi \
			 -I/opt/homebrew/include \
             -Iinclude

LDFLAGS := -L/opt/homebrew/lib -ldpp -lmongocxx1 -lbsoncxx1 -lssl -lcrypto -lz -pthread
else
CXXFLAGS := -std=c++20 -Wall -Werror -Wpedantic \
			-I/usr/local/include/mongocxx/v_noabi \
			-I/usr/local/include/bsoncxx/v_noabi \
			-Iinclude

LDFLAGS := -ldpp -lmongocxx1 -lbsoncxx1 -lssl -lcrypto -lz -pthread
endif

MAKEFLAGS += -j$(shell echo $(shell nproc) / 2 | bc)

# ——— Project Layout ———
SRCDIR   := src
BUILDDIR := build
TARGET   := mason

# find all .cc under src/, map them to .o under build/
SRCS  := $(shell find $(SRCDIR) -name '*.cc')
OBJS  := $(patsubst $(SRCDIR)/%.cc,$(BUILDDIR)/%.o,$(SRCS))

# ——— Default target ———
all: CXXFLAGS += -O3
all: $(TARGET)

# link
$(TARGET): $(OBJS)
	$(CXX) $^ -o $@ $(LDFLAGS)

# compile
$(BUILDDIR)/%.o: $(SRCDIR)/%.cc
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# clean up
.PHONY: clean
clean:
	rm -rf $(BUILDDIR) $(TARGET)

# debug builds add the -g flag
.PHONY: debug
debug: CXXFLAGS += -g -DDEBUG
debug: $(TARGET)

.PHONY: proddebug
proddebug: CXXFLAGS += -g
proddebug: $(TARGET)
