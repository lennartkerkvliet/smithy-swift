/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration.serde.json

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.defaultName
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeEncodeGeneratable
import software.amazon.smithy.swift.codegen.integration.serde.getDefaultValueOfShapeType
import software.amazon.smithy.swift.codegen.isBoxed

abstract class MemberShapeEncodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeEncodeGeneratable {

    private val primitiveSymbols: MutableSet<ShapeType> = hashSetOf(
        ShapeType.INTEGER, ShapeType.BYTE, ShapeType.SHORT,
        ShapeType.LONG, ShapeType.FLOAT, ShapeType.DOUBLE, ShapeType.BOOLEAN
    )

    fun renderListMember(
        member: MemberShape,
        memberTarget: Shape,
        containerName: String,
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member)
        val listContainerName = "${memberName}Container"
        writer.openBlock("if let $memberName = $memberName {", "}") {
            if (member.hasTrait(XmlFlattenedTrait::class.java)) {
                writer.write("var $listContainerName = $containerName.nestedUnkeyedContainer(forKey: .$memberName)")
                renderListMemberItems(memberName, listContainerName, memberTarget, false)
            } else {
                writer.write("var $listContainerName = $containerName.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: .$memberName)")
                renderListMemberItems(memberName, listContainerName, memberTarget, true)
            }
        }
    }

    private fun renderListMemberItems(
        collectionName: String,
        listContainerName: String,
        targetShape: Shape,
        isKeyed: Boolean
    ) {
        val iteratorName = "${targetShape.defaultName().toLowerCase()}0"
        val forKey = if (isKeyed) ", forKey: .member" else ""
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (targetShape) {
                is CollectionShape -> {
                    writer.write("try $listContainerName.encode($iteratorName$forKey)")
                }
                is MapShape -> {
                    throw Exception("Maps Not supported yet")
                }
                else -> {
                    throw Exception("Other shapes not supported yet")
                }
            }
        }
    }

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val symbol = ctx.symbolProvider.toSymbol(memberTarget)
        val memberName = ctx.symbolProvider.toMemberName(member)
        val isBoxed = symbol.isBoxed()
        if (isBoxed) {
            writer.openBlock("if let $memberName = $memberName {", "}") {
                writer.write("try $containerName.encode($memberName, forKey: .$memberName)")
            }
        } else {
            if (primitiveSymbols.contains(memberTarget.type)) {
                val defaultValue = getDefaultValueOfShapeType(memberTarget.type)
                writer.openBlock("if $memberName != $defaultValue {", "}") {
                    writer.write("try $containerName.encode($memberName, forKey: .$memberName)")
                }
            } else {
                writer.write("try $containerName.encode($memberName, forKey: .$memberName)")
            }
        }
    }
}