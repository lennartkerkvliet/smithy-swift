package software.amazon.smithy.swift.codegen.integration.serde.xml

import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.model.traits.XmlFlattenedTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.serde.MemberShapeDecodeGeneratable
import software.amazon.smithy.swift.codegen.isBoxed

abstract class MemberShapeDecodeXMLGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val writer: SwiftWriter,
    private val defaultTimestampFormat: TimestampFormatTrait.Format
) : MemberShapeDecodeGeneratable {

    fun renderListMember(
        member: MemberShape,
        memberTarget: CollectionShape,
        containerName: String
    ) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        val memberIsFlattened = member.hasTrait(XmlFlattenedTrait::class.java)
        var currContainerName = containerName
        var currContainerKey = ".$memberName"
        if (!memberIsFlattened) {
            val nextContainerName = "${memberName}Container"
            writer.write("let $nextContainerName = try $currContainerName.nestedContainer(keyedBy: WrappedListMember.CodingKeys.self, forKey: $currContainerKey)")
            currContainerKey = ".member"
            currContainerName = nextContainerName
        }

        val decodedTempVariableName = "${memberName}Decoded0"
        val itemContainerName = "${memberName}ItemContainer"
        val memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        writer.write("let $itemContainerName = try $currContainerName.decodeIfPresent(${memberTargetSymbol.name}.self, forKey: $currContainerKey)")
        writer.write("var $decodedTempVariableName:\$T = nil", memberTargetSymbol)
        writer.openBlock("if let $itemContainerName = $itemContainerName {", "}") {
            writer.write("$decodedTempVariableName = $memberTargetSymbol()")

            val nestedTarget = ctx.model.expectShape(memberTarget.member.target)
            renderListMemberItems(nestedTarget, decodedTempVariableName, itemContainerName)
        }
        writer.write("$memberName = $decodedTempVariableName")
    }

    private fun renderListMemberItems(shape: Shape, decodedMemberName: String, collectionName: String) {
        val iteratorName = "${shape.type.name.toLowerCase()}0"
        writer.openBlock("for $iteratorName in $collectionName {", "}") {
            when (shape) {
                is TimestampShape -> {
                    throw Exception("renderListMemberItems: timestamp not supported")
                }
                is CollectionShape -> {
                    throw Exception("renderListMemberItems: recursive collections not supported")
                }
                is MapShape -> {
                    throw Exception("renderListMemberItems: maps not supported")
                }
                else -> {
                    writer.write("$decodedMemberName?.append($iteratorName)")
                }
            }
        }
    }

    fun renderScalarMember(member: MemberShape, memberTarget: Shape, containerName: String) {
        val memberName = ctx.symbolProvider.toMemberName(member).removeSurrounding("`", "`")
        var memberTargetSymbol = ctx.symbolProvider.toSymbol(memberTarget)
        val decodeVerb = if (memberTargetSymbol.isBoxed()) "decodeIfPresent" else "decode"
        val decodedMemberName = "${memberName}Decoded"
        writer.write("let $decodedMemberName = try $containerName.$decodeVerb(${memberTargetSymbol.name}.self, forKey: .$memberName)")
        writer.write("$memberName = $decodedMemberName")
    }
}