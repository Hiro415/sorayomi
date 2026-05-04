#!/usr/bin/env python3
"""
Generate Sorayomi.xcodeproj/project.pbxproj for the Sorayomi iOS app.
Enumerates all .swift files under Sorayomi/ and creates a proper Xcode project.
"""

import os
import hashlib
import sys

# === Configuration ===
PROJECT_NAME = "Sorayomi"
BUNDLE_ID = "com.sorayomi.app"
DEPLOYMENT_TARGET = "17.0"
SWIFT_VERSION = "6.0"
DEVELOPMENT_TEAM = ""  # Fill in with your team ID
SOURCE_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), PROJECT_NAME)
XCODEPROJ_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), f"{PROJECT_NAME}.xcodeproj")

def generate_uuid(seed: str) -> str:
    """Generate a deterministic 24-char hex UUID from a seed string."""
    h = hashlib.md5(seed.encode()).hexdigest().upper()
    return h[:24]

def collect_swift_files(root_dir: str):
    """Collect all .swift files relative to the project root."""
    swift_files = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Skip hidden dirs
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        for f in sorted(filenames):
            if f.endswith('.swift'):
                full_path = os.path.join(dirpath, f)
                rel_path = os.path.relpath(full_path, os.path.dirname(root_dir))
                swift_files.append(rel_path)
    return sorted(swift_files)

def collect_resource_files(root_dir: str):
    """Collect non-swift resource files (plist, json, etc.).

    .xcassets directories are treated as opaque bundles — we add the
    directory itself as a single resource and do NOT recurse into it.
    """
    # Extensions for individual resource files
    file_resource_exts = {'.plist', '.json', '.storekit', '.xcprivacy', '.entitlements'}
    # Extensions for bundle directories (treated as single resources)
    bundle_dir_exts = {'.xcassets'}
    resources = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        # Check for bundle directories — add them as resources and skip recursion
        bundle_dirs = [d for d in dirnames if os.path.splitext(d)[1].lower() in bundle_dir_exts]
        for bd in bundle_dirs:
            full_path = os.path.join(dirpath, bd)
            rel_path = os.path.relpath(full_path, os.path.dirname(root_dir))
            resources.append(rel_path)
        # Remove bundle dirs from dirnames so os.walk won't recurse into them
        dirnames[:] = [d for d in dirnames if os.path.splitext(d)[1].lower() not in bundle_dir_exts]
        for f in sorted(filenames):
            ext = os.path.splitext(f)[1].lower()
            if ext in file_resource_exts:
                full_path = os.path.join(dirpath, f)
                rel_path = os.path.relpath(full_path, os.path.dirname(root_dir))
                resources.append(rel_path)
    return sorted(resources)

def build_group_tree(file_paths):
    """Build a tree structure from file paths for PBXGroup generation."""
    tree = {}
    for path in file_paths:
        parts = path.split(os.sep)
        node = tree
        for part in parts[:-1]:
            if part not in node:
                node[part] = {}
            node = node[part]
        # Leaf node
        node[parts[-1]] = None
    return tree

def generate_pbxproj(swift_files, resource_files):
    """Generate the full project.pbxproj content."""

    # Generate UUIDs for each file
    file_refs = {}  # path -> (fileRefUUID, buildFileUUID)
    for f in swift_files:
        file_refs[f] = (
            generate_uuid(f"fileref_{f}"),
            generate_uuid(f"buildfile_{f}")
        )

    resource_refs = {}
    for f in resource_files:
        resource_refs[f] = (
            generate_uuid(f"fileref_{f}"),
            generate_uuid(f"buildres_{f}")
        )

    # Project-level UUIDs
    ROOT_GROUP_UUID = generate_uuid("root_group")
    PROJECT_UUID = generate_uuid("project")
    TARGET_UUID = generate_uuid("target")
    SOURCES_BUILD_PHASE_UUID = generate_uuid("sources_build_phase")
    RESOURCES_BUILD_PHASE_UUID = generate_uuid("resources_build_phase")
    FRAMEWORKS_BUILD_PHASE_UUID = generate_uuid("frameworks_build_phase")
    DEBUG_CONFIG_UUID = generate_uuid("debug_config")
    RELEASE_CONFIG_UUID = generate_uuid("release_config")
    TARGET_DEBUG_CONFIG_UUID = generate_uuid("target_debug_config")
    TARGET_RELEASE_CONFIG_UUID = generate_uuid("target_release_config")
    PROJECT_CONFIG_LIST_UUID = generate_uuid("project_config_list")
    TARGET_CONFIG_LIST_UUID = generate_uuid("target_config_list")
    PRODUCTS_GROUP_UUID = generate_uuid("products_group")
    PRODUCT_REF_UUID = generate_uuid("product_ref")
    MAIN_SOURCE_GROUP_UUID = generate_uuid("main_source_group")

    # Build group UUIDs
    group_uuids = {}
    all_paths = swift_files + resource_files
    dirs_seen = set()
    for f in all_paths:
        parts = f.split(os.sep)
        for i in range(1, len(parts)):
            dir_path = os.sep.join(parts[:i])
            if dir_path not in dirs_seen:
                dirs_seen.add(dir_path)
                group_uuids[dir_path] = generate_uuid(f"group_{dir_path}")

    lines = []
    lines.append('// !$*UTF8*$!')
    lines.append('{')
    lines.append('\tarchiveVersion = 1;')
    lines.append('\tclasses = {')
    lines.append('\t};')
    lines.append('\tobjectVersion = 56;')
    lines.append('\tobjects = {')
    lines.append('')

    # === PBXBuildFile section ===
    lines.append('/* Begin PBXBuildFile section */')
    for f in swift_files:
        ref_uuid, build_uuid = file_refs[f]
        fname = os.path.basename(f)
        lines.append(f'\t\t{build_uuid} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref_uuid} /* {fname} */; }};')
    for f in resource_files:
        ref_uuid, build_uuid = resource_refs[f]
        fname = os.path.basename(f)
        lines.append(f'\t\t{build_uuid} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {ref_uuid} /* {fname} */; }};')
    lines.append('/* End PBXBuildFile section */')
    lines.append('')

    # === PBXFileReference section ===
    lines.append('/* Begin PBXFileReference section */')
    for f in swift_files:
        ref_uuid, _ = file_refs[f]
        fname = os.path.basename(f)
        lines.append(f'\t\t{ref_uuid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{fname}"; sourceTree = "<group>"; }};')
    for f in resource_files:
        ref_uuid, _ = resource_refs[f]
        fname = os.path.basename(f)
        ext = os.path.splitext(fname)[1]
        file_type = {
            '.plist': 'text.plist.xml',
            '.json': 'text.json',
            '.storekit': 'text',
            '.xcassets': 'folder.assetcatalog',
            '.xcprivacy': 'text.plist.xml',
            '.entitlements': 'text.plist.entitlements',
        }.get(ext, 'text')
        lines.append(f'\t\t{ref_uuid} /* {fname} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = "{fname}"; sourceTree = "<group>"; }};')
    # Product reference
    lines.append(f'\t\t{PRODUCT_REF_UUID} /* {PROJECT_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "{PROJECT_NAME}.app"; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append('/* End PBXFileReference section */')
    lines.append('')

    # === PBXFrameworksBuildPhase section ===
    lines.append('/* Begin PBXFrameworksBuildPhase section */')
    lines.append(f'\t\t{FRAMEWORKS_BUILD_PHASE_UUID} /* Frameworks */ = {{')
    lines.append('\t\t\tisa = PBXFrameworksBuildPhase;')
    lines.append('\t\t\tbuildActionMask = 2147483647;')
    lines.append('\t\t\tfiles = (')
    lines.append('\t\t\t);')
    lines.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    lines.append('\t\t};')
    lines.append('/* End PBXFrameworksBuildPhase section */')
    lines.append('')

    # === PBXGroup section ===
    lines.append('/* Begin PBXGroup section */')

    # Root group
    root_children = []
    # Add Sorayomi main source group
    root_children.append(f'{MAIN_SOURCE_GROUP_UUID} /* {PROJECT_NAME} */')
    root_children.append(f'{PRODUCTS_GROUP_UUID} /* Products */')

    lines.append(f'\t\t{ROOT_GROUP_UUID} = {{')
    lines.append('\t\t\tisa = PBXGroup;')
    lines.append('\t\t\tchildren = (')
    for child in root_children:
        lines.append(f'\t\t\t\t{child},')
    lines.append('\t\t\t);')
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append('\t\t};')

    # Products group
    lines.append(f'\t\t{PRODUCTS_GROUP_UUID} /* Products */ = {{')
    lines.append('\t\t\tisa = PBXGroup;')
    lines.append('\t\t\tchildren = (')
    lines.append(f'\t\t\t\t{PRODUCT_REF_UUID} /* {PROJECT_NAME}.app */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tname = Products;')
    lines.append('\t\t\tsourceTree = "<group>";')
    lines.append('\t\t};')

    # Build group tree for source files
    def emit_group(dir_path, tree_node, group_uuid, group_name, is_source_root=False):
        """Recursively emit PBXGroup entries."""
        children_lines = []

        # Subdirectories first (sorted)
        subdirs = sorted([k for k, v in tree_node.items() if v is not None and isinstance(v, dict)])
        for subdir in subdirs:
            sub_path = os.path.join(dir_path, subdir) if dir_path else subdir
            sub_uuid = group_uuids.get(sub_path, generate_uuid(f"group_{sub_path}"))
            children_lines.append(f'\t\t\t\t{sub_uuid} /* {subdir} */,')
            emit_group(sub_path, tree_node[subdir], sub_uuid, subdir)

        # Files (sorted)
        files = sorted([k for k, v in tree_node.items() if v is None])
        for fname in files:
            file_path = os.path.join(dir_path, fname) if dir_path else fname
            if file_path in file_refs:
                ref_uuid = file_refs[file_path][0]
            elif file_path in resource_refs:
                ref_uuid = resource_refs[file_path][0]
            else:
                continue
            children_lines.append(f'\t\t\t\t{ref_uuid} /* {fname} */,')

        lines.append(f'\t\t{group_uuid} /* {group_name} */ = {{')
        lines.append('\t\t\tisa = PBXGroup;')
        lines.append('\t\t\tchildren = (')
        for cl in children_lines:
            lines.append(cl)
        lines.append('\t\t\t);')
        if is_source_root:
            lines.append(f'\t\t\tpath = "{group_name}";')
        else:
            lines.append(f'\t\t\tpath = "{group_name}";')
        lines.append('\t\t\tsourceTree = "<group>";')
        lines.append('\t\t};')

    # Build tree from all files
    tree = build_group_tree(all_paths)
    if PROJECT_NAME in tree:
        emit_group(PROJECT_NAME, tree[PROJECT_NAME], MAIN_SOURCE_GROUP_UUID, PROJECT_NAME, is_source_root=True)

    lines.append('/* End PBXGroup section */')
    lines.append('')

    # === PBXNativeTarget section ===
    lines.append('/* Begin PBXNativeTarget section */')
    lines.append(f'\t\t{TARGET_UUID} /* {PROJECT_NAME} */ = {{')
    lines.append('\t\t\tisa = PBXNativeTarget;')
    lines.append(f'\t\t\tbuildConfigurationList = {TARGET_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}" */;')
    lines.append('\t\t\tbuildPhases = (')
    lines.append(f'\t\t\t\t{SOURCES_BUILD_PHASE_UUID} /* Sources */,')
    lines.append(f'\t\t\t\t{FRAMEWORKS_BUILD_PHASE_UUID} /* Frameworks */,')
    lines.append(f'\t\t\t\t{RESOURCES_BUILD_PHASE_UUID} /* Resources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tbuildRules = (')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdependencies = (')
    lines.append('\t\t\t);')
    lines.append(f'\t\t\tname = "{PROJECT_NAME}";')
    lines.append(f'\t\t\tproductName = "{PROJECT_NAME}";')
    lines.append(f'\t\t\tproductReference = {PRODUCT_REF_UUID} /* {PROJECT_NAME}.app */;')
    lines.append('\t\t\tproductType = "com.apple.product-type.application";')
    lines.append('\t\t};')
    lines.append('/* End PBXNativeTarget section */')
    lines.append('')

    # === PBXProject section ===
    lines.append('/* Begin PBXProject section */')
    lines.append(f'\t\t{PROJECT_UUID} /* Project object */ = {{')
    lines.append('\t\t\tisa = PBXProject;')
    lines.append(f'\t\t\tbuildConfigurationList = {PROJECT_CONFIG_LIST_UUID} /* Build configuration list for PBXProject "{PROJECT_NAME}" */;')
    lines.append('\t\t\tcompatibilityVersion = "Xcode 14.0";')
    lines.append('\t\t\tdevelopmentRegion = ja;')
    lines.append('\t\t\thasScannedForEncodings = 0;')
    lines.append('\t\t\tknownRegions = (')
    lines.append('\t\t\t\tja,')
    lines.append('\t\t\t\tBase,')
    lines.append('\t\t\t);')
    lines.append(f'\t\t\tmainGroup = {ROOT_GROUP_UUID};')
    lines.append(f'\t\t\tproductRefGroup = {PRODUCTS_GROUP_UUID} /* Products */;')
    lines.append('\t\t\tprojectDirPath = "";')
    lines.append('\t\t\tprojectRoot = "";')
    lines.append('\t\t\ttargets = (')
    lines.append(f'\t\t\t\t{TARGET_UUID} /* {PROJECT_NAME} */,')
    lines.append('\t\t\t);')
    lines.append('\t\t};')
    lines.append('/* End PBXProject section */')
    lines.append('')

    # === PBXResourcesBuildPhase section ===
    lines.append('/* Begin PBXResourcesBuildPhase section */')
    lines.append(f'\t\t{RESOURCES_BUILD_PHASE_UUID} /* Resources */ = {{')
    lines.append('\t\t\tisa = PBXResourcesBuildPhase;')
    lines.append('\t\t\tbuildActionMask = 2147483647;')
    lines.append('\t\t\tfiles = (')
    for f in resource_files:
        _, build_uuid = resource_refs[f]
        fname = os.path.basename(f)
        lines.append(f'\t\t\t\t{build_uuid} /* {fname} in Resources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    lines.append('\t\t};')
    lines.append('/* End PBXResourcesBuildPhase section */')
    lines.append('')

    # === PBXSourcesBuildPhase section ===
    lines.append('/* Begin PBXSourcesBuildPhase section */')
    lines.append(f'\t\t{SOURCES_BUILD_PHASE_UUID} /* Sources */ = {{')
    lines.append('\t\t\tisa = PBXSourcesBuildPhase;')
    lines.append('\t\t\tbuildActionMask = 2147483647;')
    lines.append('\t\t\tfiles = (')
    for f in swift_files:
        _, build_uuid = file_refs[f]
        fname = os.path.basename(f)
        lines.append(f'\t\t\t\t{build_uuid} /* {fname} in Sources */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\trunOnlyForDeploymentPostprocessing = 0;')
    lines.append('\t\t};')
    lines.append('/* End PBXSourcesBuildPhase section */')
    lines.append('')

    # === XCBuildConfiguration section ===
    lines.append('/* Begin XCBuildConfiguration section */')

    # Project-level Debug
    lines.append(f'\t\t{DEBUG_CONFIG_UUID} /* Debug */ = {{')
    lines.append('\t\t\tisa = XCBuildConfiguration;')
    lines.append('\t\t\tbuildSettings = {')
    lines.append('\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
    lines.append('\t\t\t\tASSTTAGS_FILTER = "";')
    lines.append('\t\t\t\tCLANG_ANALYZER_NONNULL = YES;')
    lines.append('\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;')
    lines.append('\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
    lines.append('\t\t\t\tCLANG_ENABLE_MODULES = YES;')
    lines.append('\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;')
    lines.append('\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;')
    lines.append('\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;')
    lines.append('\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_COMMA = YES;')
    lines.append('\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;')
    lines.append('\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;')
    lines.append('\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;')
    lines.append('\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;')
    lines.append('\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;')
    lines.append('\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;')
    lines.append('\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;')
    lines.append('\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;')
    lines.append('\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;')
    lines.append('\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;')
    lines.append('\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;')
    lines.append('\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;')
    lines.append('\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;')
    lines.append('\t\t\t\tCOPY_PHASE_STRIP = NO;')
    lines.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;')
    lines.append('\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;')
    lines.append('\t\t\t\tENABLE_TESTABILITY = YES;')
    lines.append('\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;')
    lines.append('\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;')
    lines.append('\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;')
    lines.append('\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;')
    lines.append('\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;')
    lines.append('\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (')
    lines.append('\t\t\t\t\t"DEBUG=1",')
    lines.append('\t\t\t\t\t"$(inherited)",')
    lines.append('\t\t\t\t);')
    lines.append('\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;')
    lines.append('\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;')
    lines.append('\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;')
    lines.append('\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;')
    lines.append('\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;')
    lines.append('\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;')
    lines.append(f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};')
    lines.append('\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;')
    lines.append('\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;')
    lines.append('\t\t\t\tMTL_FAST_MATH = YES;')
    lines.append('\t\t\t\tONLY_ACTIVE_ARCH = YES;')
    lines.append('\t\t\t\tSDKROOT = iphoneos;')
    lines.append('\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "$(inherited) DEBUG";')
    lines.append('\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";')
    lines.append('\t\t\t};')
    lines.append(f'\t\t\tname = Debug;')
    lines.append('\t\t};')

    # Project-level Release
    lines.append(f'\t\t{RELEASE_CONFIG_UUID} /* Release */ = {{')
    lines.append('\t\t\tisa = XCBuildConfiguration;')
    lines.append('\t\t\tbuildSettings = {')
    lines.append('\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;')
    lines.append('\t\t\t\tASSTTAGS_FILTER = "";')
    lines.append('\t\t\t\tCLANG_ANALYZER_NONNULL = YES;')
    lines.append('\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;')
    lines.append('\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";')
    lines.append('\t\t\t\tCLANG_ENABLE_MODULES = YES;')
    lines.append('\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;')
    lines.append('\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;')
    lines.append('\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;')
    lines.append('\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_COMMA = YES;')
    lines.append('\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;')
    lines.append('\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;')
    lines.append('\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;')
    lines.append('\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;')
    lines.append('\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;')
    lines.append('\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;')
    lines.append('\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;')
    lines.append('\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;')
    lines.append('\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;')
    lines.append('\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;')
    lines.append('\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;')
    lines.append('\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;')
    lines.append('\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;')
    lines.append('\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;')
    lines.append('\t\t\t\tCOPY_PHASE_STRIP = NO;')
    lines.append('\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";')
    lines.append('\t\t\t\tENABLE_NS_ASSERTIONS = NO;')
    lines.append('\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;')
    lines.append('\t\t\t\tENABLE_USER_SCRIPT_SANDBOXING = YES;')
    lines.append('\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;')
    lines.append('\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;')
    lines.append('\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;')
    lines.append('\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;')
    lines.append('\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;')
    lines.append('\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;')
    lines.append('\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;')
    lines.append('\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;')
    lines.append(f'\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = {DEPLOYMENT_TARGET};')
    lines.append('\t\t\t\tLOCALIZATION_PREFERS_STRING_CATALOGS = YES;')
    lines.append('\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;')
    lines.append('\t\t\t\tMTL_FAST_MATH = YES;')
    lines.append('\t\t\t\tSDKROOT = iphoneos;')
    lines.append('\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;')
    lines.append('\t\t\t\tVALIDATE_PRODUCT = YES;')
    lines.append('\t\t\t};')
    lines.append(f'\t\t\tname = Release;')
    lines.append('\t\t};')

    # Target-level Debug
    lines.append(f'\t\t{TARGET_DEBUG_CONFIG_UUID} /* Debug */ = {{')
    lines.append('\t\t\tisa = XCBuildConfiguration;')
    lines.append('\t\t\tbuildSettings = {')
    lines.append(f'\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')
    lines.append(f'\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;')
    lines.append('\t\t\t\tCODE_SIGN_STYLE = Automatic;')
    lines.append('\t\t\t\tCURRENT_PROJECT_VERSION = 1;')
    if DEVELOPMENT_TEAM:
        lines.append(f'\t\t\t\tDEVELOPMENT_TEAM = {DEVELOPMENT_TEAM};')
    lines.append('\t\t\t\tENABLE_PREVIEWS = YES;')
    lines.append('\t\t\t\tGENERATE_INFOPLIST_FILE = YES;')
    lines.append('\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "宙よみ";')
    lines.append(f'\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;')
    lines.append('\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;')
    lines.append('\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;')
    lines.append('\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;')
    lines.append('\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";')
    lines.append('\t\t\t\tINFOPLIST_KEY_NSPhotoLibraryUsageDescription = "プロフィール写真の設定に使用します。";')
    lines.append('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (')
    lines.append('\t\t\t\t\t"$(inherited)",')
    lines.append('\t\t\t\t\t"@executable_path/Frameworks",')
    lines.append('\t\t\t\t);')
    lines.append(f'\t\t\t\tMARKETING_VERSION = 1.0;')
    lines.append(f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}";')
    lines.append(f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
    lines.append(f'\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;')
    lines.append(f'\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;')
    lines.append(f'\t\t\t\tSWIFT_VERSION = 5.0;')
    lines.append('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
    lines.append('\t\t\t};')
    lines.append(f'\t\t\tname = Debug;')
    lines.append('\t\t};')

    # Target-level Release
    lines.append(f'\t\t{TARGET_RELEASE_CONFIG_UUID} /* Release */ = {{')
    lines.append('\t\t\tisa = XCBuildConfiguration;')
    lines.append('\t\t\tbuildSettings = {')
    lines.append(f'\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;')
    lines.append(f'\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;')
    lines.append('\t\t\t\tCODE_SIGN_STYLE = Automatic;')
    lines.append('\t\t\t\tCURRENT_PROJECT_VERSION = 1;')
    if DEVELOPMENT_TEAM:
        lines.append(f'\t\t\t\tDEVELOPMENT_TEAM = {DEVELOPMENT_TEAM};')
    lines.append('\t\t\t\tENABLE_PREVIEWS = YES;')
    lines.append('\t\t\t\tGENERATE_INFOPLIST_FILE = YES;')
    lines.append('\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "宙よみ";')
    lines.append(f'\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;')
    lines.append('\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;')
    lines.append('\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;')
    lines.append('\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;')
    lines.append('\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown";')
    lines.append('\t\t\t\tINFOPLIST_KEY_NSPhotoLibraryUsageDescription = "プロフィール写真の設定に使用します。";')
    lines.append('\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (')
    lines.append('\t\t\t\t\t"$(inherited)",')
    lines.append('\t\t\t\t\t"@executable_path/Frameworks",')
    lines.append('\t\t\t\t);')
    lines.append(f'\t\t\t\tMARKETING_VERSION = 1.0;')
    lines.append(f'\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = "{BUNDLE_ID}";')
    lines.append(f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";')
    lines.append(f'\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;')
    lines.append(f'\t\t\t\tSWIFT_STRICT_CONCURRENCY = complete;')
    lines.append(f'\t\t\t\tSWIFT_VERSION = 5.0;')
    lines.append('\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";')
    lines.append('\t\t\t};')
    lines.append(f'\t\t\tname = Release;')
    lines.append('\t\t};')

    lines.append('/* End XCBuildConfiguration section */')
    lines.append('')

    # === XCConfigurationList section ===
    lines.append('/* Begin XCConfigurationList section */')

    # Project config list
    lines.append(f'\t\t{PROJECT_CONFIG_LIST_UUID} /* Build configuration list for PBXProject "{PROJECT_NAME}" */ = {{')
    lines.append('\t\t\tisa = XCConfigurationList;')
    lines.append('\t\t\tbuildConfigurations = (')
    lines.append(f'\t\t\t\t{DEBUG_CONFIG_UUID} /* Debug */,')
    lines.append(f'\t\t\t\t{RELEASE_CONFIG_UUID} /* Release */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append('\t\t\tdefaultConfigurationName = Release;')
    lines.append('\t\t};')

    # Target config list
    lines.append(f'\t\t{TARGET_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "{PROJECT_NAME}" */ = {{')
    lines.append('\t\t\tisa = XCConfigurationList;')
    lines.append('\t\t\tbuildConfigurations = (')
    lines.append(f'\t\t\t\t{TARGET_DEBUG_CONFIG_UUID} /* Debug */,')
    lines.append(f'\t\t\t\t{TARGET_RELEASE_CONFIG_UUID} /* Release */,')
    lines.append('\t\t\t);')
    lines.append('\t\t\tdefaultConfigurationIsVisible = 0;')
    lines.append('\t\t\tdefaultConfigurationName = Release;')
    lines.append('\t\t};')

    lines.append('/* End XCConfigurationList section */')
    lines.append('')

    # Close objects and root
    lines.append('\t};')
    lines.append(f'\trootObject = {PROJECT_UUID} /* Project object */;')
    lines.append('}')

    return '\n'.join(lines)


def main():
    print(f"Source root: {SOURCE_ROOT}")

    swift_files = collect_swift_files(SOURCE_ROOT)
    resource_files = collect_resource_files(SOURCE_ROOT)

    print(f"Found {len(swift_files)} Swift files")
    print(f"Found {len(resource_files)} resource files")

    pbxproj = generate_pbxproj(swift_files, resource_files)

    # Create .xcodeproj directory
    os.makedirs(XCODEPROJ_DIR, exist_ok=True)

    # Write project.pbxproj
    pbxproj_path = os.path.join(XCODEPROJ_DIR, "project.pbxproj")
    with open(pbxproj_path, 'w') as f:
        f.write(pbxproj)

    print(f"Generated: {pbxproj_path}")
    print(f"Open with: open {XCODEPROJ_DIR}")

    # Also list the files for verification
    for f in swift_files[:5]:
        print(f"  {f}")
    if len(swift_files) > 5:
        print(f"  ... and {len(swift_files) - 5} more")


if __name__ == "__main__":
    main()
