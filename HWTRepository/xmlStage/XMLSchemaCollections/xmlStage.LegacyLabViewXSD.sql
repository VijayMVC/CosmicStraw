﻿CREATE XML SCHEMA COLLECTION
	xmlStage.LegacyLabViewXSD
AS N'<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">
	<xs:element name="root">
		<xs:complexType>
			<xs:sequence>
				<xs:element name="header">
					<xs:complexType>
						<xs:sequence>
							<xs:element name="Result_File" type="xs:string"/>
							<xs:element name="Start_Time" type="xs:string"/>
							<xs:element name="Finish_Time" type="xs:string"/>
							<xs:element name="Test_Duration" type="xs:string"/>
							<xs:element name="Project_Name" type="xs:string"/>
							<xs:element name="Firmware_Rev" type="xs:unsignedInt"/>
							<xs:element name="Hardware_Rev" type="xs:string"/>
							<xs:element name="Part_SN" type="xs:string"/>
							<xs:element name="Operator_Name" type="xs:string"/>
							<xs:element name="Test_Station_ID" type="xs:string"/>
							<xs:element name="Test_Name" type="xs:string"/>
							<xs:element name="Test_Config_File" type="xs:string"/>
							<xs:element name="Test_Code_Path_Name" type="xs:string"/>
							<xs:element name="Test_Code_Rev" type="xs:string"/>
							<xs:element name="HWTSys_Code_Rev" type="xs:string"/>
							<xs:element name="Kdrive_Path" type="xs:string"/>
							<xs:element name="equipment" minOccurs="0">
								<xs:complexType>
									<xs:sequence>
										<xs:element name="equipment_element" minOccurs="0" maxOccurs="unbounded">
											<xs:complexType>
												<xs:sequence>
													<xs:element name="Description" type="xs:string"/>
													<xs:element name="Asset" type="xs:string"/>
													<xs:element name="Calibration_Due_Date" type="xs:string"/>
													<xs:element name="Cost_Center" type="xs:unsignedInt"/>
												</xs:sequence>
											</xs:complexType>
										</xs:element>
									</xs:sequence>
								</xs:complexType>
							</xs:element>
							<xs:element name="External_File_Info" type="xs:string"/>
							<xs:element name="options" minOccurs="0">
								<xs:complexType>
									<xs:sequence>
										<xs:element name="option_element" maxOccurs="unbounded">
											<xs:complexType>
												<xs:sequence>
													<xs:choice maxOccurs="unbounded">
														<xs:element name="name" type="xs:string"/>
														<xs:element name="type" type="xs:string"/>
														<xs:element name="units" type="xs:string"/>
														<xs:element name="value" type="xs:string"/>
													</xs:choice>
												</xs:sequence>
											</xs:complexType>
										</xs:element>
										<xs:element name="AppConst_element" minOccurs="0" maxOccurs="unbounded">
											<xs:complexType>
												<xs:sequence>
													<xs:choice maxOccurs="unbounded">
														<xs:element name="name" type="xs:string"/>
														<xs:element name="type" type="xs:string"/>
														<xs:element name="units" type="xs:string"/>
														<xs:element name="value" type="xs:string"/>
													</xs:choice>
												</xs:sequence>
											</xs:complexType>
										</xs:element>
									</xs:sequence>
								</xs:complexType>
							</xs:element>
							<xs:element name="Comments" type="xs:string"/>
							<xs:element name="LibraryInfo" minOccurs="0">
								<xs:complexType>
									<xs:sequence>
										<xs:element name="file" minOccurs="0" maxOccurs="unbounded">
											<xs:complexType>
												<xs:attribute name="name" type="xs:string" use="required"/>
												<xs:attribute name="rev" type="xs:string" use="required"/>
												<xs:attribute name="status" type="xs:string" use="required"/>
												<xs:attribute name="HashCode" type="xs:string" use="required"/>
											</xs:complexType>
										</xs:element>
									</xs:sequence>
								</xs:complexType>
							</xs:element>
						</xs:sequence>
					</xs:complexType>
				</xs:element>
				<xs:element name="vector" minOccurs="0" maxOccurs="unbounded">
					<xs:complexType>
						<xs:sequence>
							<xs:element name="num" type="xs:unsignedShort"/>
							<xs:element name="Loop" type="xs:unsignedShort" minOccurs="0"/>
							<xs:element name="vector_element" maxOccurs="unbounded">
								<xs:complexType>
									<xs:sequence>
										<xs:element name="name" type="xs:string"/>
										<xs:element name="type" type="xs:string"/>
										<xs:element name="units" type="xs:string"/>
										<xs:element name="value" type="xs:string"/>
									</xs:sequence>
								</xs:complexType>
							</xs:element>
							<xs:element name="ReqID" type="xs:string" minOccurs="0" maxOccurs="unbounded"/>
							<xs:element name="result_element" minOccurs="0" maxOccurs="unbounded">
								<xs:complexType>
									<xs:sequence>
										<xs:element name="name" type="xs:string"/>
										<xs:choice maxOccurs="unbounded">
											<xs:element name="units" type="xs:string"/>
											<xs:element name="type" type="xs:string"/>
											<xs:element name="value" type="xs:string" minOccurs="0" maxOccurs="unbounded"/>
										</xs:choice>
									</xs:sequence>
								</xs:complexType>
							</xs:element>
							<xs:element name="error_element" minOccurs="0">
								<xs:complexType>
									<xs:sequence>
										<xs:element name="test_error">
											<xs:complexType>
												<xs:simpleContent>
													<xs:extension base="xs:string">
														<xs:attribute name="code" type="xs:int" use="required"/>
													</xs:extension>
												</xs:simpleContent>
											</xs:complexType>
										</xs:element>
									</xs:sequence>
								</xs:complexType>
							</xs:element>
							<xs:element name="Timestamp">
								<xs:complexType>
									<xs:sequence>
										<xs:element name="StartTime" type="xs:string"/>
										<xs:element name="EndTime" type="xs:string"/>
									</xs:sequence>
								</xs:complexType>
							</xs:element>
						</xs:sequence>
					</xs:complexType>
				</xs:element>
			</xs:sequence>
		</xs:complexType>
	</xs:element>
</xs:schema>'
;