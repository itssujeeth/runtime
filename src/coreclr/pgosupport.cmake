include(CheckIPOSupported)
check_ipo_supported(RESULT HAVE_LTO)

# Adds Profile Guided Optimization (PGO) flags to the current target
function(add_pgo TargetName)
    if(CLR_CMAKE_PGO_INSTRUMENT)
        if(CLR_CMAKE_HOST_WIN32)
            set_property(TARGET ${TargetName} APPEND_STRING PROPERTY LINK_FLAGS_RELEASE        " /LTCG /GENPROFILE")
            set_property(TARGET ${TargetName} APPEND_STRING PROPERTY LINK_FLAGS_RELWITHDEBINFO " /LTCG /GENPROFILE")
        else(CLR_CMAKE_HOST_WIN32)
            if(UPPERCASE_CMAKE_BUILD_TYPE STREQUAL RELEASE OR UPPERCASE_CMAKE_BUILD_TYPE STREQUAL RELWITHDEBINFO)
                target_compile_options(${TargetName} PRIVATE -flto -fprofile-instr-generate)
                set_property(TARGET ${TargetName} APPEND_STRING PROPERTY LINK_FLAGS " -flto -fuse-ld=gold -fprofile-instr-generate")
            endif(UPPERCASE_CMAKE_BUILD_TYPE STREQUAL RELEASE OR UPPERCASE_CMAKE_BUILD_TYPE STREQUAL RELWITHDEBINFO)
        endif(CLR_CMAKE_HOST_WIN32)
    elseif(CLR_CMAKE_PGO_OPTIMIZE)
        if(CLR_CMAKE_HOST_WIN32)
            set(ProfileFileName "${TargetName}.pgd")
        else(CLR_CMAKE_HOST_WIN32)
            set(ProfileFileName "${TargetName}.profdata")
        endif(CLR_CMAKE_HOST_WIN32)

        file(TO_NATIVE_PATH
            "${CLR_CMAKE_OPTDATA_PATH}/data/${ProfileFileName}"
            ProfilePath
        )

        # If we don't have profile data availble, gracefully fall back to a non-PGO opt build
        if(NOT EXISTS ${ProfilePath})
            message("PGO data file NOT found: ${ProfilePath}")
        else(NOT EXISTS ${ProfilePath})
            if(CLR_CMAKE_HOST_WIN32)
                set_property(TARGET ${TargetName} APPEND_STRING PROPERTY LINK_FLAGS_RELEASE        " /LTCG /USEPROFILE:PGD=${ProfilePath}")
                set_property(TARGET ${TargetName} APPEND_STRING PROPERTY LINK_FLAGS_RELWITHDEBINFO " /LTCG /USEPROFILE:PGD=${ProfilePath}")
            else(CLR_CMAKE_HOST_WIN32)
                if(UPPERCASE_CMAKE_BUILD_TYPE STREQUAL RELEASE OR UPPERCASE_CMAKE_BUILD_TYPE STREQUAL RELWITHDEBINFO)
                    if(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3.6)
                        if(HAVE_LTO)
                            target_compile_options(${TargetName} PRIVATE -flto -fprofile-instr-use=${ProfilePath} -Wno-profile-instr-out-of-date -Wno-profile-instr-unprofiled)
                            set_property(TARGET ${TargetName} APPEND_STRING PROPERTY LINK_FLAGS " -flto -fuse-ld=gold -fprofile-instr-use=${ProfilePath}")
                        else(HAVE_LTO)
                            message(WARNING "LTO is not supported, skipping profile guided optimizations")
                        endif(HAVE_LTO)
                    else(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3.6)
                        message(WARNING "PGO is not supported; Clang 3.6 or later is required for profile guided optimizations")
                    endif(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3.6)
                endif(UPPERCASE_CMAKE_BUILD_TYPE STREQUAL RELEASE OR UPPERCASE_CMAKE_BUILD_TYPE STREQUAL RELWITHDEBINFO)
            endif(CLR_CMAKE_HOST_WIN32)
        endif(NOT EXISTS ${ProfilePath})
    endif(CLR_CMAKE_PGO_INSTRUMENT)
endfunction(add_pgo)
