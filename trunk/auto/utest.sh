# generate utest Makefile
#
# params:
#     $SRS_OBJS the objs directory to store the Makefile. ie. ./objs
#     $SRS_OBJS_DIR the objs directory for Makefile. ie. objs
#     $SRS_MAKEFILE the makefile name. ie. Makefile
#
#     $APP_NAME the app name to output. ie. srs_utest
#     $MODULE_DIR the src dir of utest code. ie. src/utest
#     $LINK_OPTIONS the link options for utest. ie. -lpthread -ldl

FILE=${SRS_OBJS}/utest/${SRS_MAKEFILE}
# create dir for Makefile
mkdir -p ${SRS_OBJS}/utest

# the prefix to generate the objs/utest/Makefile
# dirs relative to current dir(objs/utest), it's trunk/objs/utest
# trunk of srs, which contains the src dir, relative to objs/utest, it's trunk
SRS_TRUNK_PREFIX=../../..
# gest dir, relative to objs/utest, it's trunk/objs/gtest
GTEST_DIR=${SRS_TRUNK_PREFIX}/${SRS_OBJS_DIR}/gtest

cat << END > ${FILE}
# user must run make the ${SRS_OBJS_DIR}/utest dir
# at the same dir of Makefile.

# A sample Makefile for building Google Test and using it in user
# tests.  Please tweak it to suit your environment and project.  You
# may want to move it to your project's root directory.
#
# SYNOPSIS:
#
#   make [all]  - makes everything.
#   make TARGET - makes the given target.
#   make clean  - removes all files generated by make.

# Please tweak the following variable definitions as needed by your
# project, except GTEST_HEADERS, which you can use in your own targets
# but shouldn't modify.

# Points to the root of Google Test, relative to where this file is.
# Remember to tweak this if you move this file.
GTEST_DIR = ${GTEST_DIR}

# Where to find user code.
USER_DIR = .

# Flags passed to the preprocessor.
CPPFLAGS += -I\$(GTEST_DIR)/include

# Flags passed to the C++ compiler.
CXXFLAGS += ${CXXFLAGS} -Wextra ${UTEST_EXTRA_DEFINES}

# Always use c++98, because c++14 will fail for CentOS7(GCC6).
CXXFLAGS += -std=c++98

# All tests produced by this Makefile.  Remember to add new tests you
# created to the list.
TESTS = ${SRS_TRUNK_PREFIX}/${SRS_OBJS_DIR}/${APP_NAME}

# All Google Test headers.  Usually you shouldn't change this
# definition.
GTEST_HEADERS = \$(GTEST_DIR)/include/gtest/*.h \\
                \$(GTEST_DIR)/include/gtest/internal/*.h

# House-keeping build targets.

all : \$(TESTS)

clean :
	rm -f \$(TESTS) gtest.a gtest_main.a *.o

# Builds gtest.a and gtest_main.a.

# Usually you shouldn't tweak such internal variables, indicated by a
# trailing _.
GTEST_SRCS_ = \$(GTEST_DIR)/src/*.cc \$(GTEST_DIR)/src/*.h \$(GTEST_HEADERS)

# For simplicity and to avoid depending on Google Test's
# implementation details, the dependencies specified below are
# conservative and not optimized.  This is fine as Google Test
# compiles fast and for ordinary users its source rarely changes.
gtest-all.o : \$(GTEST_SRCS_)
	\$(CXX) \$(CPPFLAGS) -I\$(GTEST_DIR) \$(CXXFLAGS) -c \\
            \$(GTEST_DIR)/src/gtest-all.cc

gtest_main.o : \$(GTEST_SRCS_)
	\$(CXX) \$(CPPFLAGS) -I\$(GTEST_DIR) \$(CXXFLAGS) -c \\
            \$(GTEST_DIR)/src/gtest_main.cc

gtest.a : gtest-all.o
	\$(AR) \$(ARFLAGS) \$@ \$^

gtest_main.a : gtest-all.o gtest_main.o
	\$(AR) \$(ARFLAGS) \$@ \$^

# Builds a sample test.  A test should link with either gtest.a or
# gtest_main.a, depending on whether it defines its own main()
# function.

#####################################################################################
#####################################################################################
# SRS(Simple RTMP Server) utest section
#####################################################################################
#####################################################################################

END

#####################################################################################
# Includes, the include dir.
echo "# Includes, the include dir." >> ${FILE}
#
# current module header files
echo -n "SRS_UTEST_INC = -I${SRS_TRUNK_PREFIX}/${MODULE_DIR} " >> ${FILE}
#
# depends module header files
for item in ${MODULE_DEPENDS[*]}; do
    DEP_INCS_NAME="${item}_INCS"
    echo -n "-I${SRS_TRUNK_PREFIX}/${!DEP_INCS_NAME} " >> ${FILE}
done
#
# depends library header files
for item in ${ModuleLibIncs[*]}; do
    echo -n "-I${SRS_TRUNK_PREFIX}/${item} " >> ${FILE}
done
echo "" >> ${FILE}; echo "" >> ${FILE}

#####################################################################################
# Depends, the depends objects
echo "# Depends, the depends objects" >> ${FILE}
#
# current module header files
echo -n "SRS_UTEST_DEPS = " >> ${FILE}
for item in ${MODULE_OBJS[*]}; do
    FILE_NAME=${item%.*}
    echo -n "${SRS_TRUNK_PREFIX}/${SRS_OBJS_DIR}/${FILE_NAME}.o " >> ${FILE}
done
echo "" >> ${FILE}; echo "" >> ${FILE}
#
echo "# Depends, utest header files" >> ${FILE}
DEPS_NAME="UTEST_DEPS"
echo -n "${DEPS_NAME} = " >> ${FILE}
for item in ${MODULE_FILES[*]}; do
    HEADER_FILE="${SRS_TRUNK_PREFIX}/${MODULE_DIR}/${item}.hpp"
    echo -n " ${HEADER_FILE}" >> ${FILE}
done
echo "" >> ${FILE}; echo "" >> ${FILE}

#####################################################################################
# Objects, build each object of utest
echo "# Objects, build each object of utest" >> ${FILE}
#
MODULE_OBJS=()
for item in ${MODULE_FILES[*]}; do
    MODULE_OBJS="${MODULE_OBJS[@]} ${item}.o"
    cat << END >> ${FILE}
${item}.o : \$(${DEPS_NAME}) ${SRS_TRUNK_PREFIX}/${MODULE_DIR}/${item}.cpp \$(SRS_UTEST_DEPS)
	\$(CXX) \$(CPPFLAGS) \$(CXXFLAGS) \$(SRS_UTEST_INC) -c ${SRS_TRUNK_PREFIX}/${MODULE_DIR}/${item}.cpp -o \$@
END
done
echo "" >> ${FILE}

#####################################################################################
# App for utest
#
# link all depends libraries
echo "# link all depends libraries" >> ${FILE}
echo -n "DEPS_LIBRARIES_FILES = " >> ${FILE}
for item in ${ModuleLibFiles[*]}; do
    if [[ -f ${item} ]]; then
        echo -n "${SRS_TRUNK_PREFIX}/${item} " >> ${FILE}
    else
        echo -n "${item} " >> ${FILE}
    fi
done
echo "" >> ${FILE}; echo "" >> ${FILE}
#
echo "# generate the utest binary" >> ${FILE}
cat << END >> ${FILE}
${SRS_TRUNK_PREFIX}/${SRS_OBJS_DIR}/${APP_NAME} : \$(SRS_UTEST_DEPS) ${MODULE_OBJS} gtest.a
	\$(CXX) -o \$@ \$(CPPFLAGS) \$(CXXFLAGS) \$^ \$(DEPS_LIBRARIES_FILES) ${LINK_OPTIONS}
END

#####################################################################################
# parent Makefile, to create module output dir before compile it.
echo "	@mkdir -p ${SRS_OBJS_DIR}/utest" >> ${SRS_WORKDIR}/${SRS_MAKEFILE}

echo -n "Generate utest ok"; echo '!';
